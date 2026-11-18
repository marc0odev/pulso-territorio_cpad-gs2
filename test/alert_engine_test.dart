import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_territorio/core/utils/formatters.dart';
import 'package:pulso_territorio/data/models/alert.dart';
import 'package:pulso_territorio/data/models/indicator.dart';
import 'package:pulso_territorio/data/models/region.dart';
import 'package:pulso_territorio/data/models/territory_snapshot.dart';
import 'package:pulso_territorio/data/models/thresholds.dart';
import 'package:pulso_territorio/data/services/simulated_city_api.dart';
import 'package:pulso_territorio/domain/alert_engine.dart';
import 'package:pulso_territorio/domain/social_impact.dart';

final _today = dateOnly(DateTime.now());
final _region = Regions.all.first;

IndicatorSeries _series(
  String id, {
  required List<double> history,
  List<double> forecast = const [],
  DashboardKind dashboard = DashboardKind.resources,
  double? mape,
  double? capacity,
  List<double>? probability,
}) => IndicatorSeries(
  id: id,
  name: id,
  unit: 'u',
  dashboard: dashboard,
  origin: DataOrigin.synthetic,
  sourceLabel: 'teste',
  description: 'teste',
  forecastMethod: 'teste',
  history: [
    for (var i = 0; i < history.length; i++)
      DataPoint(
        _today.subtract(Duration(days: history.length - 1 - i)),
        history[i],
      ),
  ],
  forecast: [
    for (var i = 0; i < forecast.length; i++)
      DataPoint(_today.add(Duration(days: i + 1)), forecast[i]),
  ],
  backtestMape: mape,
  capacity: capacity,
  forecastProbability: probability,
);

List<TerritoryAlert> _evaluate(
  List<IndicatorSeries> indicators, [
  Thresholds thresholds = const Thresholds(),
]) => const AlertEngine().evaluate(
  region: _region,
  snapshot: TerritorySnapshot(
    regionId: _region.id,
    fetchedAt: _today,
    indicators: indicators,
    serviceBreakdown: const {},
  ),
  thresholds: thresholds,
);

void main() {
  group('Regra de água', () {
    test(
      'não gera alerta quando consumo e projeção ficam abaixo do limiar',
      () {
        final alerts = _evaluate([
          _series(
            IndicatorIds.water,
            history: List.filled(20, 120),
            forecast: List.filled(7, 121),
          ),
        ]);
        expect(alerts, isEmpty);
      },
    );

    test('gera alerta quando a projeção cruza o limiar', () {
      final alerts = _evaluate([
        _series(
          IndicatorIds.water,
          history: List.generate(20, (i) => 130.0 + i),
          forecast: [150, 151, 152, 153, 154, 155, 156],
          mape: 0.05,
        ),
      ]);
      expect(alerts, hasLength(1));
      expect(alerts.single.indicatorId, IndicatorIds.water);
      expect(alerts.single.id, '${_region.id}-agua');
      expect(alerts.single.confidence, closeTo(0.9, 1e-9));
    });

    test('severidade cresce com a distância em relação ao limiar', () {
      AlertSeverity severityFor(double level) => _evaluate([
        _series(
          IndicatorIds.water,
          history: List.filled(20, level),
          forecast: List.filled(7, level),
        ),
      ]).single.severity;

      expect(severityFor(152), AlertSeverity.attention);
      expect(severityFor(160), AlertSeverity.warning);
      expect(severityFor(185), AlertSeverity.critical);
    });

    test('respeita o limiar configurado pelo gestor', () {
      final indicators = [
        _series(
          IndicatorIds.water,
          history: List.filled(20, 140),
          forecast: List.filled(7, 140),
        ),
      ];
      expect(_evaluate(indicators), isEmpty);
      expect(_evaluate(indicators, const Thresholds(water: 130)), hasLength(1));
    });
  });

  group('Regras de clima', () {
    test('chuva: confiança combina probabilidade e antecedência', () {
      final alerts = _evaluate([
        _series(
          IndicatorIds.rain,
          dashboard: DashboardKind.climate,
          history: List.filled(14, 2),
          forecast: [5, 70, 3],
          probability: [40, 90, 20],
        ),
      ]);
      expect(alerts, hasLength(1));
      // Pico em D+2 → fator 0,9; probabilidade 90% → 0,81.
      expect(alerts.single.confidence, closeTo(0.81, 1e-9));
      expect(alerts.single.severity, AlertSeverity.critical);
    });

    test('calor: três ou mais dias acima do limiar é crítico', () {
      final alerts = _evaluate([
        _series(
          IndicatorIds.tempMax,
          dashboard: DashboardKind.climate,
          history: List.filled(14, 28),
          forecast: [33, 33, 33, 30],
        ),
      ]);
      expect(alerts.single.severity, AlertSeverity.critical);
    });

    test('ar: não alerta abaixo da diretriz da OMS', () {
      final alerts = _evaluate([
        _series(
          IndicatorIds.pm25,
          dashboard: DashboardKind.climate,
          history: List.filled(14, 9),
          forecast: [10, 12, 14],
        ),
      ]);
      expect(alerts, isEmpty);
    });
  });

  group('Demais regras', () {
    test('energia: detecta pico acima de 2 desvios-padrão', () {
      final normal = [
        for (var i = 0; i < 20; i++) 5.0 + (i.isEven ? 0.1 : -0.1),
      ];
      expect(
        _evaluate([_series(IndicatorIds.energy, history: normal)]),
        isEmpty,
      );
      expect(
        _evaluate([
          _series(IndicatorIds.energy, history: [...normal, 6.5]),
        ]),
        hasLength(1),
      );
    });

    test('resíduos: alerta quando a projeção encosta na capacidade', () {
      final alerts = _evaluate([
        _series(
          IndicatorIds.waste,
          dashboard: DashboardKind.services,
          history: List.filled(20, 800),
          forecast: List.filled(7, 860),
          capacity: 900,
        ),
      ]);
      expect(alerts, hasLength(1)); // 860/900 = 95,6% ≥ 90%
    });

    test('serviços: alerta quando a demanda semanal cresce além do limiar', () {
      final alerts = _evaluate([
        _series(
          IndicatorIds.services,
          dashboard: DashboardKind.services,
          history: [...List.filled(7, 100.0), ...List.filled(7, 130.0)],
        ),
      ]);
      expect(alerts, hasLength(1));
    });
  });

  group('Transparência e ordenação', () {
    late List<TerritoryAlert> alerts;

    setUp(() {
      alerts = _evaluate([
        _series(
          IndicatorIds.water,
          history: List.filled(20, 152),
          forecast: List.filled(7, 152),
        ),
        _series(
          IndicatorIds.rain,
          dashboard: DashboardKind.climate,
          history: List.filled(14, 2),
          forecast: [80],
          probability: [95],
        ),
      ]);
    });

    test('todo alerta traz evidência, confiança, limitações e opções', () {
      expect(alerts, hasLength(2));
      for (final alert in alerts) {
        expect(alert.evidence, isNotEmpty);
        expect(alert.limitations, isNotEmpty);
        expect(alert.unreliableWhen, isNotEmpty);
        expect(alert.optionsForReview, isNotEmpty);
        expect(alert.confidenceReason, isNotEmpty);
        expect(alert.plainSummary, isNotEmpty);
        expect(alert.confidence, inInclusiveRange(0.0, 1.0));
      }
    });

    test('os mais severos vêm primeiro', () {
      expect(alerts.first.indicatorId, IndicatorIds.rain);
      expect(alerts.first.severity, AlertSeverity.critical);
    });
  });

  test('confiança de tendência deriva do MAPE do backtest', () {
    expect(AlertEngine.trendConfidence(null), 0.5);
    expect(AlertEngine.trendConfidence(0.10), closeTo(0.8, 1e-9));
    expect(AlertEngine.trendConfidence(0.02), 0.9); // teto
    expect(AlertEngine.trendConfidence(0.60), 0.35); // piso
  });

  test('nota do índice de bem-estar varia de 0 a 100', () {
    expect(SocialImpactCalculator.scoreFor(0.5), 100);
    expect(SocialImpactCalculator.scoreFor(1.1), 50);
    expect(SocialImpactCalculator.scoreFor(2), 0);
  });

  test(
    'serviço simulado é determinístico e alimenta o motor de alertas',
    () async {
      const api = SimulatedCityApi(latency: Duration.zero);
      final first = await api.fetch(_region, now: DateTime(2026, 11, 14));
      final second = await api.fetch(_region, now: DateTime(2026, 11, 14));

      expect(first.indicators, hasLength(4));
      for (var i = 0; i < first.indicators.length; i++) {
        expect(
          first.indicators[i].historyValues,
          second.indicators[i].historyValues,
        );
        expect(first.indicators[i].history, hasLength(30));
        expect(first.indicators[i].forecast, hasLength(7));
        expect(first.indicators[i].backtestMape, isNotNull);
      }
    },
  );
}

import 'dart:math';

import '../../core/utils/formatters.dart';
import '../../core/utils/stats.dart';
import '../models/indicator.dart';
import '../models/region.dart';

class SimulatedCityPayload {
  const SimulatedCityPayload({
    required this.indicators,
    required this.serviceBreakdown,
  });

  final List<IndicatorSeries> indicators;
  final Map<String, int> serviceBreakdown;
}

/// Perfil que dá a cada região um comportamento próprio nos dados sintéticos.
class _Profile {
  const _Profile({
    required this.water,
    required this.waterTrend,
    required this.energy,
    required this.energySpike,
    required this.waste,
    required this.wasteTrend,
    required this.wasteCapacity,
    required this.services,
    required this.servicesGrowth,
  });

  final double water, waterTrend;
  final double energy, energySpike;
  final double waste, wasteTrend, wasteCapacity;
  final double services, servicesGrowth;
}

/// Simula o serviço de dados da prefeitura (consumo de água e energia,
/// resíduos e chamados). Os valores são SINTÉTICOS: gerados de forma
/// determinística por região e por dia, com tendência, sazonalidade semanal e
/// ruído, para exercitar o app sem expor dados reais de ninguém.
class SimulatedCityApi {
  const SimulatedCityApi({this.latency = const Duration(milliseconds: 700)});

  /// Atraso artificial para reproduzir o tempo de resposta de uma API.
  final Duration latency;

  static const historyDays = 30;
  static const horizonDays = 7;
  static const _source = 'Serviço municipal simulado (dados sintéticos)';

  static const _profiles = <String, _Profile>{
    'centro': _Profile(
      water: 138,
      waterTrend: 0.9,
      energy: 6.2,
      energySpike: 1,
      waste: 520,
      wasteTrend: 0.2,
      wasteCapacity: 600,
      services: 310,
      servicesGrowth: 0,
    ),
    'norte': _Profile(
      water: 128,
      waterTrend: 0.1,
      energy: 5.4,
      energySpike: 1.3,
      waste: 780,
      wasteTrend: 0.3,
      wasteCapacity: 900,
      services: 420,
      servicesGrowth: 0.008,
    ),
    'sul': _Profile(
      water: 146,
      waterTrend: -0.3,
      energy: 5.9,
      energySpike: 1,
      waste: 800,
      wasteTrend: 2.4,
      wasteCapacity: 900,
      services: 510,
      servicesGrowth: 0,
    ),
    'leste': _Profile(
      water: 122,
      waterTrend: 0.2,
      energy: 4.8,
      energySpike: 1,
      waste: 950,
      wasteTrend: 0.4,
      wasteCapacity: 1100,
      services: 640,
      servicesGrowth: 0.035,
    ),
    'oeste': _Profile(
      water: 160,
      waterTrend: -0.2,
      energy: 7.1,
      energySpike: 1,
      waste: 430,
      wasteTrend: 0.1,
      wasteCapacity: 520,
      services: 280,
      servicesGrowth: 0,
    ),
  };

  static const _categories = <String, double>{
    'Iluminação pública': 0.24,
    'Buracos e vias': 0.27,
    'Coleta de lixo': 0.19,
    'Poda de árvores': 0.12,
    'Água e esgoto': 0.18,
  };

  Future<SimulatedCityPayload> fetch(Region region, {DateTime? now}) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final today = dateOnly(now ?? DateTime.now());
    final profile = _profiles[region.id] ?? _profiles.values.first;
    final dates = [
      for (var i = historyDays - 1; i >= 0; i--)
        today.subtract(Duration(days: i)),
    ];

    double noise(String key, DateTime date, double amplitude) {
      final rng = Random(_seed('${region.id}/$key', date));
      return (rng.nextDouble() * 2 - 1) * amplitude;
    }

    bool weekend(DateTime d) =>
        d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

    final water = <double>[], energy = <double>[];
    final waste = <double>[], services = <double>[];
    for (var i = 0; i < dates.length; i++) {
      final d = dates[i];
      water.add(
        profile.water +
            profile.waterTrend * i +
            (weekend(d) ? profile.water * 0.03 : 0) +
            noise('agua', d, 2.5),
      );
      final isLast = i == dates.length - 1;
      energy.add(
        profile.energy *
                (weekend(d) ? 1.05 : 1) *
                (isLast ? profile.energySpike : 1) +
            noise('energia', d, profile.energy * 0.03),
      );
      waste.add(
        profile.waste +
            profile.wasteTrend * i +
            (d.weekday == DateTime.monday ? profile.waste * 0.05 : 0) +
            noise('residuos', d, profile.waste * 0.015),
      );
      final growthDays = max(0, i - (dates.length - 11));
      services.add(
        (profile.services *
                    pow(1 + profile.servicesGrowth, growthDays) *
                    (weekend(d) ? 0.7 : 1) +
                noise('servicos', d, profile.services * 0.04))
            .roundToDouble(),
      );
    }

    IndicatorSeries build({
      required String id,
      required String name,
      required String unit,
      required DashboardKind dashboard,
      required String description,
      required List<double> values,
      double? capacity,
    }) {
      final projected = Stats.forecastLinear(values, horizon: horizonDays);
      return IndicatorSeries(
        id: id,
        name: name,
        unit: unit,
        dashboard: dashboard,
        origin: DataOrigin.synthetic,
        sourceLabel: _source,
        description: description,
        forecastMethod:
            'Regressão linear (mínimos quadrados) sobre os últimos '
            '14 dias, projetada 7 dias à frente.',
        history: [
          for (var i = 0; i < dates.length; i++) DataPoint(dates[i], values[i]),
        ],
        forecast: [
          for (var h = 0; h < projected.length; h++)
            DataPoint(
              today.add(Duration(days: h + 1)),
              max(0, projected[h]).toDouble(),
            ),
        ],
        backtestMape: Stats.backtestMape(values, horizon: horizonDays),
        capacity: capacity,
      );
    }

    final lastWeekCalls = services
        .sublist(services.length - 7)
        .fold<double>(0, (a, b) => a + b);

    return SimulatedCityPayload(
      indicators: [
        build(
          id: IndicatorIds.water,
          name: 'Consumo de água',
          unit: 'L/hab/dia',
          dashboard: DashboardKind.resources,
          description: 'Consumo médio diário de água por habitante.',
          values: water,
        ),
        build(
          id: IndicatorIds.energy,
          name: 'Consumo de energia',
          unit: 'kWh/dom/dia',
          dashboard: DashboardKind.resources,
          description: 'Consumo médio diário de energia por domicílio.',
          values: energy,
        ),
        build(
          id: IndicatorIds.waste,
          name: 'Resíduos coletados',
          unit: 't/dia',
          dashboard: DashboardKind.services,
          description:
              'Toneladas de resíduos coletadas por dia, comparadas à '
              'capacidade de coleta da região.',
          values: waste,
          capacity: profile.wasteCapacity,
        ),
        build(
          id: IndicatorIds.services,
          name: 'Demanda por serviços',
          unit: 'chamados/dia',
          dashboard: DashboardKind.services,
          description:
              'Chamados abertos por dia na central de atendimento '
              '(zeladoria urbana).',
          values: services,
        ),
      ],
      serviceBreakdown: {
        for (final entry in _categories.entries)
          entry.key: (lastWeekCalls * entry.value).round(),
      },
    );
  }

  /// Semente estável entre execuções e plataformas (não usa `hashCode`).
  static int _seed(String key, DateTime date) {
    var hash = date.year * 10000 + date.month * 100 + date.day;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    return hash;
  }
}

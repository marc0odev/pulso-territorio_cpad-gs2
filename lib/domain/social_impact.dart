import 'dart:math';

import '../data/models/indicator.dart';
import '../data/models/region.dart';
import '../data/models/territory_snapshot.dart';
import '../data/models/thresholds.dart';

/// Indicadores de benefício social: traduzem o desempenho analítico em
/// efeitos para as pessoas. São estimativas, sempre rotuladas como tal.
class SocialImpact {
  const SocialImpact({
    required this.wellbeingIndex,
    required this.componentScores,
    required this.waterSavingLitersPerDay,
    required this.peopleSupplied,
    required this.peopleCovered,
  });

  /// Índice de Bem-Estar Territorial, 0 (pior) a 100 (melhor).
  final int wellbeingIndex;

  /// Nota 0–100 de cada indicador que compõe o índice (nome → nota).
  final Map<String, int> componentScores;

  /// Litros/dia que deixariam de ser consumidos se a região voltasse à
  /// referência de 110 L/hab/dia.
  final double waterSavingLitersPerDay;

  /// Pessoas que esse volume abasteceria por um dia.
  final int peopleSupplied;

  /// Moradores cobertos pelo monitoramento da região.
  final int peopleCovered;
}

class SocialImpactCalculator {
  const SocialImpactCalculator();

  /// Consumo diário por pessoa que a ONU considera suficiente para as
  /// necessidades básicas.
  static const unWaterReference = 110.0;

  SocialImpact compute({
    required Region region,
    required TerritorySnapshot snapshot,
    required Thresholds thresholds,
  }) {
    final scores = <String, int>{};
    for (final series in snapshot.indicators) {
      final limit = thresholds.limitFor(series);
      final value = _representativeValue(series);
      if (limit == null || limit <= 0 || value == null) continue;
      scores[series.name] = scoreFor(value / limit);
    }
    final index = scores.isEmpty
        ? 0
        : (scores.values.reduce((a, b) => a + b) / scores.length).round();

    final waterAverage =
        snapshot.indicator(IndicatorIds.water)?.lastWeekAverage ?? 0;
    final saving =
        max(0.0, waterAverage - unWaterReference) * region.population;

    return SocialImpact(
      wellbeingIndex: index,
      componentScores: scores,
      waterSavingLitersPerDay: saving,
      peopleSupplied: (saving / unWaterReference).round(),
      peopleCovered: region.population,
    );
  }

  /// 100 quando o valor está até 80% do limiar; 0 a partir de 140%;
  /// variação linear entre os dois pontos.
  static int scoreFor(double ratioToLimit) {
    const best = 0.8, worst = 1.4;
    final normalized = (worst - ratioToLimit) / (worst - best);
    return (normalized.clamp(0.0, 1.0) * 100).round();
  }

  /// Para clima usa o pior valor previsto; para os demais, a média da semana.
  double? _representativeValue(IndicatorSeries series) {
    if (series.dashboard == DashboardKind.climate) {
      if (series.forecast.isEmpty) return series.latest;
      return series.forecastValues.reduce(max);
    }
    return series.lastWeekAverage;
  }
}

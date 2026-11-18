import 'indicator.dart';

/// Fotografia dos dados de uma região em um instante. É o que vai para o
/// cache local e permite que o app continue útil sem conexão.
class TerritorySnapshot {
  const TerritorySnapshot({
    required this.regionId,
    required this.fetchedAt,
    required this.indicators,
    required this.serviceBreakdown,
    this.fromCache = false,
    this.climateFromCache = false,
  });

  final String regionId;
  final DateTime fetchedAt;
  final List<IndicatorSeries> indicators;

  /// Chamados da última semana por categoria (serviço simulado).
  final Map<String, int> serviceBreakdown;

  /// `true` quando tudo veio do cache (sem conexão).
  final bool fromCache;

  /// `true` quando só os dados de clima vieram do cache ou estão ausentes.
  final bool climateFromCache;

  bool get isStale => fromCache || climateFromCache;

  IndicatorSeries? indicator(String id) {
    for (final s in indicators) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<IndicatorSeries> byDashboard(DashboardKind kind) => [
    for (final s in indicators)
      if (s.dashboard == kind) s,
  ];

  TerritorySnapshot copyWith({bool? fromCache, bool? climateFromCache}) =>
      TerritorySnapshot(
        regionId: regionId,
        fetchedAt: fetchedAt,
        indicators: indicators,
        serviceBreakdown: serviceBreakdown,
        fromCache: fromCache ?? this.fromCache,
        climateFromCache: climateFromCache ?? this.climateFromCache,
      );

  Map<String, dynamic> toJson() => {
    'regionId': regionId,
    'fetchedAt': fetchedAt.toIso8601String(),
    'indicators': [for (final s in indicators) s.toJson()],
    'serviceBreakdown': serviceBreakdown,
  };

  factory TerritorySnapshot.fromJson(Map<String, dynamic> json) =>
      TerritorySnapshot(
        regionId: json['regionId'] as String,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        indicators: [
          for (final s in json['indicators'] as List)
            IndicatorSeries.fromJson(s as Map<String, dynamic>),
        ],
        serviceBreakdown: (json['serviceBreakdown'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}

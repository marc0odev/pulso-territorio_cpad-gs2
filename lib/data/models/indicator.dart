import '../../core/utils/stats.dart';

enum DashboardKind {
  resources('recursos', 'Recursos'),
  climate('clima', 'Clima'),
  services('servicos', 'Serviços');

  const DashboardKind(this.slug, this.label);
  final String slug;
  final String label;

  static DashboardKind fromSlug(String? slug) =>
      values.firstWhere((k) => k.slug == slug, orElse: () => resources);
}

/// Origem do dado, sempre exibida ao usuário para dar transparência.
enum DataOrigin {
  real('Dado público real'),
  synthetic('Dado sintético');

  const DataOrigin(this.label);
  final String label;
}

class IndicatorIds {
  const IndicatorIds._();
  static const water = 'agua';
  static const energy = 'energia';
  static const tempMax = 'temperatura';
  static const rain = 'chuva';
  static const pm25 = 'pm25';
  static const waste = 'residuos';
  static const services = 'servicos';
}

class DataPoint {
  const DataPoint(this.date, this.value);

  final DateTime date;
  final double value;

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'v': value};

  factory DataPoint.fromJson(Map<String, dynamic> json) => DataPoint(
    DateTime.parse(json['d'] as String),
    (json['v'] as num).toDouble(),
  );
}

/// Série de um indicador territorial: histórico observado + previsão.
class IndicatorSeries {
  const IndicatorSeries({
    required this.id,
    required this.name,
    required this.unit,
    required this.dashboard,
    required this.origin,
    required this.sourceLabel,
    required this.description,
    required this.forecastMethod,
    required this.history,
    required this.forecast,
    this.backtestMape,
    this.capacity,
    this.forecastProbability,
  });

  final String id;
  final String name;
  final String unit;
  final DashboardKind dashboard;
  final DataOrigin origin;
  final String sourceLabel;
  final String description;
  final String forecastMethod;
  final List<DataPoint> history;
  final List<DataPoint> forecast;

  /// Erro percentual médio do modelo ao "prever" os últimos 7 dias conhecidos.
  final double? backtestMape;

  /// Capacidade física associada ao indicador (ex.: coleta de resíduos).
  final double? capacity;

  /// Probabilidade (0–100) associada a cada ponto da previsão, quando existir.
  final List<double>? forecastProbability;

  List<double> get historyValues => [for (final p in history) p.value];
  List<double> get forecastValues => [for (final p in forecast) p.value];

  double? get latest => history.isEmpty ? null : history.last.value;

  double? get lastWeekAverage {
    if (history.isEmpty) return null;
    final v = historyValues;
    return Stats.mean(v.sublist(v.length > 7 ? v.length - 7 : 0));
  }

  /// Variação percentual: média dos últimos 7 dias vs. os 7 dias anteriores.
  double? get weeklyTrendPercent {
    final v = historyValues;
    if (v.length < 14) return null;
    final last = Stats.mean(v.sublist(v.length - 7));
    final previous = Stats.mean(v.sublist(v.length - 14, v.length - 7));
    if (previous == 0) return null;
    return (last / previous - 1) * 100;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'dashboard': dashboard.slug,
    'origin': origin.name,
    'sourceLabel': sourceLabel,
    'description': description,
    'forecastMethod': forecastMethod,
    'history': [for (final p in history) p.toJson()],
    'forecast': [for (final p in forecast) p.toJson()],
    'backtestMape': backtestMape,
    'capacity': capacity,
    'forecastProbability': forecastProbability,
  };

  factory IndicatorSeries.fromJson(Map<String, dynamic> json) {
    List<DataPoint> points(String key) => [
      for (final p in json[key] as List)
        DataPoint.fromJson(p as Map<String, dynamic>),
    ];
    return IndicatorSeries(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      dashboard: DashboardKind.fromSlug(json['dashboard'] as String?),
      origin: DataOrigin.values.byName(json['origin'] as String),
      sourceLabel: json['sourceLabel'] as String,
      description: json['description'] as String,
      forecastMethod: json['forecastMethod'] as String,
      history: points('history'),
      forecast: points('forecast'),
      backtestMape: (json['backtestMape'] as num?)?.toDouble(),
      capacity: (json['capacity'] as num?)?.toDouble(),
      forecastProbability: (json['forecastProbability'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

import 'indicator.dart';

/// Limiares que disparam alertas. São definidos por pessoas (gestor), ficam
/// salvos no aparelho e podem ser ajustados a qualquer momento.
class Thresholds {
  const Thresholds({
    this.water = 150,
    this.rain = 50,
    this.heat = 32,
    this.pm25 = 15,
    this.wastePercent = 90,
    this.servicesGrowthPercent = 20,
  });

  /// Consumo de água, L/hab/dia.
  final double water;

  /// Chuva acumulada em um dia, mm.
  final double rain;

  /// Temperatura máxima, °C.
  final double heat;

  /// MP2,5 média diária, µg/m³ (15 = diretriz da OMS de 2021 para 24 h).
  final double pm25;

  /// Uso da capacidade de coleta de resíduos, %.
  final double wastePercent;

  /// Crescimento semanal da demanda por serviços, %.
  final double servicesGrowthPercent;

  /// Desvios-padrão acima da média para considerar um pico de energia atípico.
  static const energyZScore = 2.0;

  /// Linha de referência desenhada no gráfico do indicador, se houver.
  double? limitFor(IndicatorSeries series) => switch (series.id) {
    IndicatorIds.water => water,
    IndicatorIds.rain => rain,
    IndicatorIds.tempMax => heat,
    IndicatorIds.pm25 => pm25,
    IndicatorIds.waste =>
      series.capacity == null ? null : series.capacity! * wastePercent / 100,
    _ => null,
  };

  Map<String, dynamic> toJson() => {
    'water': water,
    'rain': rain,
    'heat': heat,
    'pm25': pm25,
    'wastePercent': wastePercent,
    'servicesGrowthPercent': servicesGrowthPercent,
  };

  factory Thresholds.fromJson(Map<String, dynamic> json) {
    const d = Thresholds();
    double read(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    return Thresholds(
      water: read('water', d.water),
      rain: read('rain', d.rain),
      heat: read('heat', d.heat),
      pm25: read('pm25', d.pm25),
      wastePercent: read('wastePercent', d.wastePercent),
      servicesGrowthPercent: read(
        'servicesGrowthPercent',
        d.servicesGrowthPercent,
      ),
    );
  }
}

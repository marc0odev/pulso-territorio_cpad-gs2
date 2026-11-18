import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/formatters.dart';
import '../models/indicator.dart';
import '../models/region.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente da Open-Meteo (https://open-meteo.com), API pública e gratuita de
/// previsão do tempo e qualidade do ar. Não exige chave de acesso.
class OpenMeteoApi {
  OpenMeteoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 12);
  static const _source = 'Open-Meteo (dados abertos, CC BY 4.0)';

  Future<List<IndicatorSeries>> fetchClimate(
    Region region, {
    DateTime? now,
  }) async {
    final today = dateOnly(now ?? DateTime.now());
    final results = await Future.wait([
      _fetchWeather(region, today),
      _fetchAirQuality(region, today),
    ]);
    return [...results[0], ...results[1]];
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw ApiException('Open-Meteo respondeu ${response.statusCode}.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Map<String, String> _baseQuery(Region region) => {
    'latitude': region.latitude.toString(),
    'longitude': region.longitude.toString(),
    'timezone': 'America/Sao_Paulo',
    'past_days': '14',
  };

  Future<List<IndicatorSeries>> _fetchWeather(
    Region region,
    DateTime today,
  ) async {
    final json = await _getJson(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        ..._baseQuery(region),
        'forecast_days': '7',
        'daily':
            'temperature_2m_max,precipitation_sum,'
            'precipitation_probability_max',
      }),
    );
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = [
      for (final d in daily['time'] as List) DateTime.parse(d as String),
    ];
    final temps = daily['temperature_2m_max'] as List;
    final rain = daily['precipitation_sum'] as List;
    final probability = daily['precipitation_probability_max'] as List;

    final tempHistory = <DataPoint>[], tempForecast = <DataPoint>[];
    final rainHistory = <DataPoint>[], rainForecast = <DataPoint>[];
    final rainProbability = <double>[];

    for (var i = 0; i < dates.length; i++) {
      final isPast = dates[i].isBefore(today);
      final t = (temps[i] as num?)?.toDouble();
      final r = (rain[i] as num?)?.toDouble();
      if (t != null) {
        (isPast ? tempHistory : tempForecast).add(DataPoint(dates[i], t));
      }
      if (r != null) {
        (isPast ? rainHistory : rainForecast).add(DataPoint(dates[i], r));
        if (!isPast) {
          rainProbability.add((probability[i] as num?)?.toDouble() ?? 50);
        }
      }
    }

    return [
      IndicatorSeries(
        id: IndicatorIds.tempMax,
        name: 'Temperatura máxima',
        unit: '°C',
        dashboard: DashboardKind.climate,
        origin: DataOrigin.real,
        sourceLabel: _source,
        description: 'Temperatura máxima diária a 2 m do solo na região.',
        forecastMethod:
            'Previsão numérica do tempo (modelos meteorológicos '
            'globais combinados pela Open-Meteo), 7 dias à frente.',
        history: tempHistory,
        forecast: tempForecast,
      ),
      IndicatorSeries(
        id: IndicatorIds.rain,
        name: 'Chuva acumulada',
        unit: 'mm/dia',
        dashboard: DashboardKind.climate,
        origin: DataOrigin.real,
        sourceLabel: _source,
        description:
            'Total de chuva por dia. Volumes altos em pouco tempo '
            'elevam o risco de alagamentos.',
        forecastMethod:
            'Previsão numérica do tempo com probabilidade de '
            'precipitação diária, 7 dias à frente.',
        history: rainHistory,
        forecast: rainForecast,
        forecastProbability: rainProbability,
      ),
    ];
  }

  Future<List<IndicatorSeries>> _fetchAirQuality(
    Region region,
    DateTime today,
  ) async {
    final json = await _getJson(
      Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        ..._baseQuery(region),
        'forecast_days': '5',
        'hourly': 'pm2_5',
      }),
    );
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List;
    final values = hourly['pm2_5'] as List;

    // Agrega as leituras horárias em média diária.
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (var i = 0; i < times.length; i++) {
      final v = (values[i] as num?)?.toDouble();
      if (v == null) continue;
      final day = (times[i] as String).substring(0, 10);
      sums[day] = (sums[day] ?? 0) + v;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final history = <DataPoint>[], forecast = <DataPoint>[];
    for (final day in sums.keys.toList()..sort()) {
      final date = DateTime.parse(day);
      final point = DataPoint(date, sums[day]! / counts[day]!);
      (date.isBefore(today) ? history : forecast).add(point);
    }

    return [
      IndicatorSeries(
        id: IndicatorIds.pm25,
        name: 'Qualidade do ar (MP2,5)',
        unit: 'µg/m³',
        dashboard: DashboardKind.climate,
        origin: DataOrigin.real,
        sourceLabel: _source,
        description:
            'Média diária de partículas finas (MP2,5), as que mais '
            'afetam a saúde respiratória.',
        forecastMethod:
            'Modelo atmosférico global (CAMS) distribuído pela '
            'Open-Meteo, 5 dias à frente.',
        history: history,
        forecast: forecast,
      ),
    ];
  }
}

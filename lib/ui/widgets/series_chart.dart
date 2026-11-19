import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/indicator.dart';
import 'indicator_widgets.dart';

/// Gráfico de um indicador: histórico (linha cheia), previsão (tracejada) e
/// limiar de alerta (linha horizontal). Usado em todos os painéis e no
/// detalhe do indicador. Para leitores de tela, expõe um resumo em texto.
class SeriesChart extends StatelessWidget {
  const SeriesChart({
    super.key,
    required this.series,
    this.limit,
    this.historyDays = 14,
    this.height = 200,
    this.asBars = false,
  });

  final IndicatorSeries series;
  final double? limit;
  final int historyDays;
  final double height;

  /// Barras em vez de linha (adequado a volumes diários, como chuva).
  final bool asBars;

  List<DataPoint> get _history => series.history.length > historyDays
      ? series.history.sublist(series.history.length - historyDays)
      : series.history;

  String _semanticSummary() {
    final buffer = StringBuffer('Gráfico de ${series.name}. ');
    final latest = series.latest;
    if (latest != null) {
      buffer.write(
        'Último valor: ${formatIndicatorValue(series, latest)} ${series.unit}. ',
      );
    }
    if (series.forecast.isNotEmpty) {
      final peak = series.forecast.reduce((a, b) => a.value >= b.value ? a : b);
      buffer.write(
        'Maior valor previsto: ${formatIndicatorValue(series, peak.value)} '
        '${series.unit} em ${fmtDate(peak.date)}. ',
      );
    }
    if (limit != null) {
      buffer.write(
        'Limiar de alerta: ${formatIndicatorValue(series, limit!)} ${series.unit}.',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final points = [...history, ...series.forecast];
    if (points.isEmpty) {
      return SizedBox(
        height: height / 2,
        child: const Center(child: Text('Sem dados para o período.')),
      );
    }

    final values = [for (final p in points) p.value, ?limit];
    final low = values.reduce(min);
    final high = values.reduce(max);
    final padding = max((high - low) * 0.15, high == 0 ? 1.0 : high * 0.02);
    final minY = asBars ? 0.0 : max(0.0, low - padding);
    final maxY = high + padding;

    final lineColor = context.colors.primary;
    final forecastColor = context.status.forecast;
    final labelStyle = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final labelStep = max(1, (points.length / 4).ceil());

    final titles = FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(
                fmtNum(value, decimals: maxY - minY < 5 ? 1 : 0),
                style: labelStyle,
                textAlign: TextAlign.right,
                textScaler: TextScaler.noScaling,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= points.length || index % labelStep != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                fmtDate(points[index].date),
                style: labelStyle,
                textScaler: TextScaler.noScaling,
              ),
            );
          },
        ),
      ),
    );

    final grid = FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: context.colors.outlineVariant, strokeWidth: 0.6),
    );

    final limitLine = ExtraLinesData(
      horizontalLines: [
        if (limit != null)
          HorizontalLine(
            y: limit!,
            color: context.status.critical,
            strokeWidth: 1.5,
            dashArray: [6, 4],
          ),
      ],
    );

    final Widget chart;
    if (asBars) {
      chart = BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          titlesData: titles,
          gridData: grid,
          borderData: FlBorderData(show: false),
          extraLinesData: limitLine,
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].value,
                    width: 6,
                    color: i < history.length ? lineColor : forecastColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      );
    } else {
      chart = LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          titlesData: titles,
          gridData: grid,
          borderData: FlBorderData(show: false),
          extraLinesData: limitLine,
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < history.length; i++)
                  FlSpot(i.toDouble(), history[i].value),
              ],
              color: lineColor,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.12),
              ),
            ),
            if (series.forecast.isNotEmpty)
              LineChartBarData(
                spots: [
                  // Começa no último ponto real para a linha não "quebrar".
                  if (history.isNotEmpty)
                    FlSpot((history.length - 1).toDouble(), history.last.value),
                  for (var i = 0; i < series.forecast.length; i++)
                    FlSpot(
                      (history.length + i).toDouble(),
                      series.forecast[i].value,
                    ),
                ],
                color: forecastColor,
                barWidth: 2.5,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _semanticSummary(),
          image: true,
          child: ExcludeSemantics(
            child: SizedBox(height: height, child: chart),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendItem(color: lineColor, label: 'Histórico'),
              if (series.forecast.isNotEmpty)
                _LegendItem(
                  color: forecastColor,
                  label: 'Previsão',
                  dashed: true,
                ),
              if (limit != null)
                _LegendItem(
                  color: context.status.critical,
                  label: 'Limiar (${formatIndicatorValue(series, limit!)})',
                  dashed: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    Widget segment(double width) =>
        Container(width: width, height: 3, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed) ...[
          segment(6),
          const SizedBox(width: 3),
          segment(6),
        ] else
          segment(15),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(label, style: context.text.labelMedium),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/indicator.dart';
import 'brand_widgets.dart';
import 'layout.dart';

IconData indicatorIcon(String indicatorId) => switch (indicatorId) {
  IndicatorIds.water => Icons.water_drop_outlined,
  IndicatorIds.energy => Icons.bolt_outlined,
  IndicatorIds.tempMax => Icons.thermostat_outlined,
  IndicatorIds.rain => Icons.thunderstorm_outlined,
  IndicatorIds.pm25 => Icons.air,
  IndicatorIds.waste => Icons.delete_outline,
  IndicatorIds.services => Icons.support_agent_outlined,
  _ => Icons.insights_outlined,
};

IconData dashboardIcon(DashboardKind kind) => switch (kind) {
  DashboardKind.resources => Icons.water_drop_outlined,
  DashboardKind.climate => Icons.wb_sunny_outlined,
  DashboardKind.services => Icons.handyman_outlined,
};

/// Casas decimais adequadas a cada unidade.
int indicatorDecimals(IndicatorSeries series) => switch (series.id) {
  IndicatorIds.energy => 2,
  IndicatorIds.waste || IndicatorIds.services => 0,
  _ => 1,
};

String formatIndicatorValue(IndicatorSeries series, double value) =>
    fmtNum(value, decimals: indicatorDecimals(series));

/// Tendência semanal. Em todos os indicadores do app, subir é sinal de
/// atenção; por isso alta usa a cor de alerta e queda a cor positiva. O ícone
/// e o texto garantem a leitura sem depender só de cor.
class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.percent});

  final double? percent;

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null) return const SizedBox.shrink();
    final stable = value.abs() < 1;
    final color = stable
        ? context.colors.onSurfaceVariant
        : (value > 0 ? context.status.warning : context.status.ok);
    final icon = stable
        ? Icons.trending_flat
        : (value > 0 ? Icons.trending_up : Icons.trending_down);
    final description = stable
        ? 'estável na semana'
        : '${value > 0 ? 'alta' : 'queda'} de ${fmtNum(value.abs())}% na semana';
    return Semantics(
      label: 'Tendência: $description',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              fmtSignedPercent(value),
              style: context.text.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selo que informa se o dado é real ou sintético.
class OriginBadge extends StatelessWidget {
  const OriginBadge({super.key, required this.origin});

  final DataOrigin origin;

  @override
  Widget build(BuildContext context) {
    final isReal = origin == DataOrigin.real;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: isReal ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        origin.label,
        style: context.text.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isReal
              ? context.colors.onPrimary
              : context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Cartão-resumo de um indicador: valor atual, tendência e origem do dado.
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.series, required this.onTap});

  final IndicatorSeries series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = series.latest;
    final valueText = latest == null
        ? '—'
        : formatIndicatorValue(series, latest);
    final trend = series.weeklyTrendPercent;
    return AppCard(
      onTap: onTap,
      color: dashboardTint(context, series.dashboard),
      semanticLabel:
          '${series.name}: $valueText ${series.unit}. '
          '${trend == null ? '' : 'Variação na semana: ${fmtSignedPercent(trend)}. '}'
          '${series.origin.label}. Toque para ver o detalhe.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: indicatorIcon(series.id)),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: context.text.titleMedium?.copyWith(
                        color: context.brand.onTint,
                      ),
                    ),
                    Text(
                      series.origin.label,
                      style: context.text.bodySmall?.copyWith(
                        color: context.brand.onTint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: context.brand.onTint),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StatPair(
            leftValue: valueText,
            leftUnit: series.unit,
            leftLabel: 'Último valor',
            rightValue: trend == null ? '—' : fmtSignedPercent(trend),
            rightLabel: 'Na semana',
            rightColor: trend == null || trend.abs() < 1
                ? null
                : (trend > 0 ? context.brand.accent : context.status.ok),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/stats.dart';
import '../../data/models/indicator.dart';
import '../../state/decisions_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_widgets.dart';
import '../widgets/indicator_widgets.dart';
import '../widgets/layout.dart';
import '../widgets/series_chart.dart';
import '../widgets/state_views.dart';
import '../widgets/territory_widgets.dart';

/// Detalhe de um indicador: histórico, previsão, método, métricas de erro e
/// os alertas que ele originou. Recebe o indicador por parâmetro de rota.
class IndicatorDetailScreen extends StatefulWidget {
  const IndicatorDetailScreen({super.key, required this.indicatorId});

  final String indicatorId;

  @override
  State<IndicatorDetailScreen> createState() => _IndicatorDetailScreenState();
}

class _IndicatorDetailScreenState extends State<IndicatorDetailScreen> {
  /// Estado local: só interessa a esta tela, por isso não vai para o provider.
  int _periodDays = 14;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final series = territory.snapshot?.indicator(widget.indicatorId);

    return Scaffold(
      appBar: AppBar(title: Text(series?.name ?? 'Indicador')),
      body: SafeArea(
        child: TerritoryStateBuilder(
          builder: (context, snapshot) {
            final current = snapshot.indicator(widget.indicatorId);
            if (current == null) {
              return EmptyView(
                icon: Icons.search_off,
                title: 'Indicador indisponível',
                message:
                    'Não há dados deste indicador para a região '
                    '${territory.selectedRegion.name} no momento.',
                actionLabel: 'Tentar novamente',
                onAction: territory.load,
              );
            }
            return _content(context, current, territory);
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    IndicatorSeries series,
    TerritoryProvider territory,
  ) {
    final thresholds = context.watch<SettingsProvider>().thresholds;
    final decisions = context.watch<DecisionsProvider>();
    final limit = thresholds.limitFor(series);
    final latest = series.latest;
    final values = series.historyValues;
    final period = values.sublist(max(0, values.length - _periodDays));
    final related = [
      for (final alert in territory.alerts)
        if (alert.indicatorId == series.id) alert,
    ];
    final hasLongHistory = series.history.length > 14;

    return PageBody(
      children: [
        StaleDataBanner(snapshot: territory.snapshot!),
        Row(
          children: [
            Icon(
              indicatorIcon(series.id),
              size: 40,
              color: context.colors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest == null
                        ? '—'
                        : '${formatIndicatorValue(series, latest)} ${series.unit}',
                    style: context.text.headlineSmall,
                  ),
                  Text(
                    '${territory.selectedRegion.name} · último valor medido',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TrendChip(percent: series.weeklyTrendPercent),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(series.description, style: context.text.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        if (hasLongHistory)
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 dias')),
                ButtonSegment(value: 14, label: Text('14 dias')),
                ButtonSegment(value: 30, label: Text('30 dias')),
              ],
              selected: {_periodDays},
              onSelectionChanged: (selection) =>
                  setState(() => _periodDays = selection.first),
            ),
          ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        AppCard(
          child: SeriesChart(
            series: series,
            limit: limit,
            historyDays: _periodDays,
            height: 240,
            asBars: series.id == IndicatorIds.rain,
          ),
        ),
        const SectionHeader('Resumo do período'),
        AppCard(
          child: Column(
            children: [
              LabeledValue(
                label: 'Média',
                value:
                    '${formatIndicatorValue(series, Stats.mean(period))} '
                    '${series.unit}',
              ),
              LabeledValue(
                label: 'Mínimo',
                value:
                    '${formatIndicatorValue(series, period.reduce(min))} '
                    '${series.unit}',
              ),
              LabeledValue(
                label: 'Máximo',
                value:
                    '${formatIndicatorValue(series, period.reduce(max))} '
                    '${series.unit}',
              ),
              if (limit != null)
                LabeledValue(
                  label: 'Limiar de alerta (definido pelo gestor)',
                  value:
                      '${formatIndicatorValue(series, limit)} ${series.unit}',
                ),
            ],
          ),
        ),
        if (series.forecast.isNotEmpty) ...[
          const SectionHeader('Previsão'),
          AppCard(
            child: Column(
              children: [
                for (final point in series.forecast)
                  LabeledValue(
                    label: fmtDate(point.date),
                    value:
                        '${formatIndicatorValue(series, point.value)} '
                        '${series.unit}',
                  ),
              ],
            ),
          ),
        ],
        const SectionHeader('Como esta previsão é feita'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OriginBadge(origin: series.origin),
              const SizedBox(height: AppSpacing.sm),
              LabeledValue(label: 'Fonte', value: series.sourceLabel),
              LabeledValue(label: 'Método', value: series.forecastMethod),
              LabeledValue(
                label: 'Erro no backtest (MAPE, 7 dias)',
                value: series.backtestMape == null
                    ? 'Não se aplica (previsão de terceiros)'
                    : fmtPercent(series.backtestMape!, decimals: 1),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Previsões são estimativas. Quanto mais distante o dia, menor '
                'a confiança.',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('Alertas deste indicador'),
        if (related.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum alerta ativo para este indicador com os limiares '
                  'atuais.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.thresholds),
                  icon: const Icon(Icons.tune),
                  label: const Text('Ajustar limiares'),
                ),
              ],
            ),
          )
        else
          for (final alert in related) ...[
            AlertTile(
              alert: alert,
              decision: decisions.statusFor(alert.id),
              onTap: () => context.pushNamed(
                AppRoutes.alert,
                pathParameters: {'alertId': alert.id},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

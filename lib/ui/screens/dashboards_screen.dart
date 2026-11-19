import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/indicator.dart';
import '../../data/models/territory_snapshot.dart';
import '../../state/settings_provider.dart';
import '../../state/territory_provider.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/indicator_widgets.dart';
import '../widgets/layout.dart';
import '../widgets/series_chart.dart';
import '../widgets/state_views.dart';
import '../widgets/territory_widgets.dart';

/// Os três painéis territoriais (Recursos, Clima e Serviços) em abas.
class DashboardsScreen extends StatefulWidget {
  const DashboardsScreen({super.key, required this.initial});

  final DashboardKind initial;

  @override
  State<DashboardsScreen> createState() => _DashboardsScreenState();
}

class _DashboardsScreenState extends State<DashboardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: DashboardKind.values.length,
    initialIndex: widget.initial.index,
    vsync: this,
  );

  @override
  void didUpdateWidget(DashboardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _tabs.animateTo(widget.initial.index);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          labelColor: context.colors.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          tabs: [
            for (final kind in DashboardKind.values)
              Tab(text: kind.label, icon: Icon(dashboardIcon(kind))),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final kind in DashboardKind.values)
                _DashboardView(kind: kind),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.kind});

  final DashboardKind kind;

  static const _intros = {
    DashboardKind.resources:
        'Consumo de água e energia da região, com a tendência projetada para '
        'a próxima semana.',
    DashboardKind.climate:
        'Temperatura, chuva e qualidade do ar: observações recentes e '
        'previsão para os próximos dias.',
    DashboardKind.services:
        'Resíduos coletados e chamados de zeladoria, para antecipar a '
        'sobrecarga dos serviços públicos.',
  };

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final thresholds = context.watch<SettingsProvider>().thresholds;

    return TerritoryStateBuilder(
      builder: (context, snapshot) {
        final seriesList = snapshot.byDashboard(kind);
        if (seriesList.isEmpty) {
          return EmptyView(
            icon: Icons.cloud_off_outlined,
            title: 'Sem dados de ${kind.label.toLowerCase()}',
            message:
                'Este painel depende de uma fonte externa que não '
                'respondeu, e ainda não há dados salvos no aparelho.',
            actionLabel: 'Tentar novamente',
            onAction: territory.load,
          );
        }
        return PageBody(
          onRefresh: territory.load,
          children: [
            StaleDataBanner(snapshot: snapshot),
            Text(
              _intros[kind]!,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final series in seriesList) ...[
              _ChartCard(series: series, limit: thresholds.limitFor(series)),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ],
            if (kind == DashboardKind.climate)
              _ForecastTable(snapshot: snapshot),
            if (kind == DashboardKind.services)
              _ServiceBreakdownCard(breakdown: snapshot.serviceBreakdown),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.series, required this.limit});

  final IndicatorSeries series;
  final double? limit;

  @override
  Widget build(BuildContext context) {
    final latest = series.latest;
    final capacity = series.capacity;
    return AppCard(
      color: dashboardTint(context, series.dashboard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: indicatorIcon(series.id), size: 40),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(series.name, style: context.text.titleMedium),
              ),
              OriginBadge(origin: series.origin),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm + AppSpacing.xs,
            children: [
              Text(
                latest == null
                    ? '—'
                    : '${formatIndicatorValue(series, latest)} ${series.unit}',
                style: context.text.headlineSmall?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: TrendChip(percent: series.weeklyTrendPercent),
              ),
            ],
          ),
          if (capacity != null && latest != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label:
                  'Uso da capacidade de coleta: '
                  '${fmtNum(latest / capacity * 100, decimals: 0)}%.',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uso da capacidade (${fmtNum(capacity, decimals: 0)} t/dia): '
                    '${fmtNum(latest / capacity * 100, decimals: 0)}%',
                    style: context.text.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    child: LinearProgressIndicator(
                      value: (latest / capacity).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: context.colors.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SeriesChart(
            series: series,
            limit: limit,
            asBars: series.id == IndicatorIds.rain,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.pushNamed(
                AppRoutes.indicator,
                pathParameters: {'indicatorId': series.id},
              ),
              icon: const Icon(Icons.query_stats),
              label: Text('Detalhar ${series.name.toLowerCase()}'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Previsão do tempo dia a dia (dados reais da Open-Meteo).
class _ForecastTable extends StatelessWidget {
  const _ForecastTable({required this.snapshot});

  final TerritorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final temperature = snapshot.indicator(IndicatorIds.tempMax);
    final rain = snapshot.indicator(IndicatorIds.rain);
    if (temperature == null || rain == null) return const SizedBox.shrink();
    final days = temperature.forecast.length < rain.forecast.length
        ? temperature.forecast.length
        : rain.forecast.length;
    final probability = rain.forecastProbability;

    Widget cell(String text, {bool header = false, TextAlign? align}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            text,
            textAlign: align ?? TextAlign.end,
            style: header
                ? context.text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  )
                : context.text.bodyMedium,
          ),
        );

    return AppCard(
      color: context.brand.sun,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Próximos $days dias', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Table(
            columnWidths: const {0: FlexColumnWidth(1.2)},
            border: TableBorder(
              horizontalInside: BorderSide(
                color: context.colors.outlineVariant,
              ),
            ),
            children: [
              TableRow(
                children: [
                  cell('Dia', header: true, align: TextAlign.start),
                  cell('Máxima', header: true),
                  cell('Chuva', header: true),
                  cell('Prob.', header: true),
                ],
              ),
              for (var i = 0; i < days; i++)
                TableRow(
                  children: [
                    cell(
                      fmtDate(temperature.forecast[i].date),
                      align: TextAlign.start,
                    ),
                    cell('${fmtNum(temperature.forecast[i].value)} °C'),
                    cell('${fmtNum(rain.forecast[i].value)} mm'),
                    cell(
                      probability != null && i < probability.length
                          ? '${fmtNum(probability[i], decimals: 0)}%'
                          : '—',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chamados da última semana por categoria, em barras horizontais.
class _ServiceBreakdownCard extends StatelessWidget {
  const _ServiceBreakdownCard({required this.breakdown});

  final Map<String, int> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final highest = entries.first.value;
    return AppCard(
      color: context.brand.peach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chamados por categoria (7 dias)',
                  style: context.text.titleMedium,
                ),
              ),
              const OriginBadge(origin: DataOrigin.synthetic),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in entries)
            Semantics(
              label: '${entry.key}: ${entry.value} chamados.',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs + 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: context.text.bodyMedium,
                          ),
                        ),
                        Text('${entry.value}', style: context.text.labelLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      child: LinearProgressIndicator(
                        value: highest == 0 ? 0 : entry.value / highest,
                        minHeight: 8,
                        backgroundColor: context.colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

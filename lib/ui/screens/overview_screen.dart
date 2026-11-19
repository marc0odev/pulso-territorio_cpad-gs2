import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/alert.dart';
import '../../data/models/indicator.dart';
import '../../data/models/territory_snapshot.dart';
import '../../domain/social_impact.dart';
import '../../state/reports_provider.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_widgets.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/indicator_widgets.dart';
import '../widgets/layout.dart';
import '../widgets/territory_widgets.dart';
import 'home_shell.dart';

/// Visão geral do território: índice de bem-estar em destaque, os três
/// painéis como etapas numeradas, benefício social e todos os indicadores.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final region = territory.selectedRegion;
    final alerts = territory.alerts;
    final impact = territory.socialImpact;
    final reportCount = context.watch<ReportsProvider>().countForRegion(
      region.id,
    );

    return TerritoryStateBuilder(
      builder: (context, snapshot) => PageBody(
        onRefresh: territory.load,
        children: [
          StaleDataBanner(snapshot: snapshot),
          const SizedBox(height: AppSpacing.sm),
          HeroHeadline(
            title: 'Acompanhe sua região!',
            subtitle:
                '${region.name} · ${fmtCompact(region.population)} '
                'moradores · atualizado em ${fmtDateTime(snapshot.fetchedAt)}',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (impact != null)
            _WellbeingHero(index: impact.wellbeingIndex, alerts: alerts),
          const SizedBox(height: AppSpacing.md),
          const HumanDecisionBanner(),
          const SectionHeader(
            'Painéis do território',
            subtitle: 'Toque em um painel para ver gráficos e previsões',
          ),
          _DashboardSteps(snapshot: snapshot, alerts: alerts),
          if (impact != null) ...[
            const SectionHeader(
              'Benefício social',
              subtitle: 'O que os números significam para as pessoas',
            ),
            _SocialImpactCard(impact: impact, reportCount: reportCount),
          ],
          const SectionHeader(
            'Indicadores',
            subtitle: 'Último valor medido e variação na semana',
          ),
          ResponsiveGrid(
            minItemWidth: 300,
            children: [
              for (final series in snapshot.indicators)
                KpiCard(
                  series: series,
                  onTap: () => context.pushNamed(
                    AppRoutes.indicator,
                    pathParameters: {'indicatorId': series.id},
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WellbeingHero extends StatelessWidget {
  const _WellbeingHero({required this.index, required this.alerts});

  final int index;
  final List<TerritoryAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final count = alerts.length;
    final badge = count == 0
        ? 'Nenhum alerta ativo'
        : '$count ${count == 1 ? 'alerta pede' : 'alertas pedem'} atenção';
    return HeroNumberCard(
      number: '$index',
      badge: badge,
      caption: 'Índice de Bem-Estar do território\n(de 0 a 100, quanto maior, melhor)',
      semanticLabel:
          'Índice de Bem-Estar do território: $index de 100. $badge.',
      onInfo: () => context.pushNamed(AppRoutes.about),
      action: HeroButton(
        label: count == 0 ? 'Ver alertas' : 'Ver o que pede atenção',
        icon: Icons.notifications_active_outlined,
        onPressed: () => context.goNamed(
          AppRoutes.home,
          queryParameters: {AppRoutes.tabParam: HomeTab.alerts.slug},
        ),
      ),
      footnote: count == 0
          ? null
          : 'Mais urgente: ${alerts.first.title} (${alerts.first.severity.label.toLowerCase()})',
    );
  }
}

class _DashboardSteps extends StatelessWidget {
  const _DashboardSteps({required this.snapshot, required this.alerts});

  final TerritorySnapshot snapshot;
  final List<TerritoryAlert> alerts;

  static const _descriptions = {
    DashboardKind.resources: 'Água e energia',
    DashboardKind.climate: 'Calor, chuva e ar',
    DashboardKind.services: 'Lixo e chamados',
  };

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minItemWidth: 150,
      children: [
        for (final kind in DashboardKind.values)
          Builder(
            builder: (context) {
              final count = alerts
                  .where(
                    (a) => snapshot.indicator(a.indicatorId)?.dashboard == kind,
                  )
                  .length;
              final status = count == 0
                  ? 'Tudo tranquilo'
                  : '$count ${count == 1 ? 'alerta' : 'alertas'}';
              return StepCard(
                number: kind.index + 1,
                title: kind.label,
                subtitle: '${_descriptions[kind]}\n$status',
                color: dashboardTint(context, kind),
                done: count == 0,
                icon: count == 0 ? null : Icons.warning_amber_rounded,
                semanticLabel:
                    'Painel ${kind.index + 1}, ${kind.label}: '
                    '${_descriptions[kind]}. $status. Toque para abrir.',
                onTap: () => context.goNamed(
                  AppRoutes.home,
                  queryParameters: {
                    AppRoutes.tabParam: HomeTab.dashboards.slug,
                    AppRoutes.dashboardParam: kind.slug,
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SocialImpactCard extends StatelessWidget {
  const _SocialImpactCard({required this.impact, required this.reportCount});

  final SocialImpact impact;
  final int reportCount;

  @override
  Widget build(BuildContext context) {
    final saving = impact.waterSavingLitersPerDay;
    return AppCard(
      color: context.brand.lilac,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.volunteer_activism_outlined),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  'Quem ganha quando o problema é evitado',
                  style: context.text.titleMedium?.copyWith(
                    color: context.brand.onTint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StatPair(
            leftValue: saving == 0 ? 'OK' : fmtCompact(saving),
            leftUnit: saving == 0 ? null : 'litros',
            leftLabel: saving == 0
                ? 'Consumo de água dentro da meta'
                : 'Água que dá para poupar por dia',
            rightValue: fmtCompact(impact.peopleSupplied),
            rightLabel: 'Pessoas que esse volume abasteceria',
            highlightRight: true,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          StatPair(
            leftValue: fmtCompact(impact.peopleCovered),
            leftLabel: 'Moradores acompanhados',
            rightValue: '$reportCount',
            rightLabel: 'Relatos de cidadãos neste aparelho',
            highlightRight: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Estimativas experimentais, calculadas em parte com dados '
            'sintéticos. Meta de água: 110 litros por pessoa por dia (ONU).',
            style: context.text.bodySmall?.copyWith(
              color: context.brand.onTint,
            ),
          ),
        ],
      ),
    );
  }
}

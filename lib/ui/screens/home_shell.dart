import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../data/models/indicator.dart';
import '../../state/territory_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/territory_widgets.dart';
import 'alerts_screen.dart';
import 'dashboards_screen.dart';
import 'map_screen.dart';
import 'overview_screen.dart';
import 'reports_screen.dart';

enum HomeTab {
  overview('inicio', 'Início', Icons.home_outlined, Icons.home),
  dashboards(
    'paineis',
    'Painéis',
    Icons.insert_chart_outlined,
    Icons.insert_chart,
  ),
  alerts(
    'alertas',
    'Alertas',
    Icons.notifications_outlined,
    Icons.notifications,
  ),
  map('mapa', 'Mapa', Icons.map_outlined, Icons.map),
  reports('ocorrencias', 'Relatos', Icons.campaign_outlined, Icons.campaign);

  const HomeTab(this.slug, this.label, this.icon, this.selectedIcon);
  final String slug;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  static HomeTab fromSlug(String? slug) =>
      values.firstWhere((t) => t.slug == slug, orElse: () => overview);
}

/// Casca da área principal: barra superior com a região (estado global) e
/// navegação por abas. A aba ativa vem da rota, então o endereço sempre
/// reflete o que está na tela. Em telas largas usa trilho lateral.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.tab, required this.dashboard});

  final HomeTab tab;
  final DashboardKind dashboard;

  static const _railBreakpoint = 720.0;

  void _goTo(BuildContext context, HomeTab target) => context.goNamed(
    AppRoutes.home,
    queryParameters: {AppRoutes.tabParam: target.slug},
  );

  Widget _icon(HomeTab item, int alertCount, {required bool selected}) {
    final icon = Icon(selected ? item.selectedIcon : item.icon);
    if (item != HomeTab.alerts || alertCount == 0) return icon;
    return Badge(label: Text('$alertCount'), child: icon);
  }

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final alertCount = territory.alerts.length;
    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;

    final body = switch (tab) {
      HomeTab.overview => const OverviewScreen(),
      HomeTab.dashboards => DashboardsScreen(initial: dashboard),
      HomeTab.alerts => const AlertsScreen(),
      HomeTab.map => const MapScreen(),
      HomeTab.reports => const ReportsScreen(),
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: AppSpacing.md + AppSpacing.xs,
        title: const RegionSelector(),
        actions: [
          CircleIconButton(
            tooltip: 'Atualizar dados',
            icon: Icons.refresh,
            onPressed: territory.status == LoadStatus.loading
                ? null
                : territory.load,
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleIconButton(
            tooltip: 'Configurações',
            icon: Icons.tune,
            onPressed: () => context.pushNamed(AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: tab.index,
                    onDestinationSelected: (i) =>
                        _goTo(context, HomeTab.values[i]),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final item in HomeTab.values)
                        NavigationRailDestination(
                          icon: _icon(item, alertCount, selected: false),
                          selectedIcon: _icon(item, alertCount, selected: true),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: wide
          ? null
          : _DotNavigationBar(
              selected: tab,
              alertCount: alertCount,
              onSelect: (item) => _goTo(context, item),
              iconBuilder: _icon,
            ),
      floatingActionButton: tab == HomeTab.reports
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(AppRoutes.newReport),
              icon: const Icon(Icons.add),
              label: const Text('Registrar ocorrência'),
            )
          : null,
    );
  }
}

/// Barra inferior leve: ícone, rótulo curto e um ponto sob a aba ativa.
class _DotNavigationBar extends StatelessWidget {
  const _DotNavigationBar({
    required this.selected,
    required this.alertCount,
    required this.onSelect,
    required this.iconBuilder,
  });

  final HomeTab selected;
  final int alertCount;
  final ValueChanged<HomeTab> onSelect;
  final Widget Function(HomeTab, int, {required bool selected}) iconBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              for (final item in HomeTab.values)
                Expanded(
                  child: Semantics(
                    selected: item == selected,
                    button: true,
                    label: item == HomeTab.alerts && alertCount > 0
                        ? '${item.label}, $alertCount ativos'
                        : item.label,
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      onTap: () => onSelect(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs + 2,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconTheme(
                              data: IconThemeData(
                                color: item == selected
                                    ? context.colors.primary
                                    : context.colors.onSurfaceVariant,
                              ),
                              child: iconBuilder(
                                item,
                                alertCount,
                                selected: item == selected,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: item == selected
                                    ? context.colors.primary
                                    : context.colors.onSurfaceVariant,
                                fontWeight: item == selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: item == selected ? 6 : 0,
                              height: 6,
                              decoration: BoxDecoration(
                                color: context.colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

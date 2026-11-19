import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/alert.dart';
import '../../state/decisions_provider.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_widgets.dart';
import '../widgets/layout.dart';
import '../widgets/state_views.dart';
import '../widgets/territory_widgets.dart';

/// Lista dos alertas preditivos da região, com filtro por severidade.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  /// Estado local: filtro de severidade (`null` = todos).
  AlertSeverity? _filter;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final decisions = context.watch<DecisionsProvider>();

    return TerritoryStateBuilder(
      builder: (context, snapshot) {
        final all = territory.alerts;
        if (all.isEmpty) {
          return EmptyView(
            icon: Icons.notifications_off_outlined,
            title: 'Nenhum alerta ativo',
            message:
                'Com os limiares atuais, nenhum indicador da '
                '${territory.selectedRegion.name} pede atenção. Você pode '
                'ajustar os limiares para deixar os alertas mais sensíveis.',
            actionLabel: 'Ajustar limiares',
            actionIcon: Icons.tune,
            onAction: () => context.pushNamed(AppRoutes.thresholds),
          );
        }
        final visible = [
          for (final alert in all)
            if (_filter == null || alert.severity == _filter) alert,
        ];
        return PageBody(
          onRefresh: territory.load,
          children: [
            StaleDataBanner(snapshot: snapshot),
            const HumanDecisionBanner(),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                FilterChip(
                  label: Text('Todos (${all.length})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final severity in AlertSeverity.values.reversed)
                  FilterChip(
                    label: Text(
                      '${severity.label} '
                      '(${all.where((a) => a.severity == severity).length})',
                    ),
                    selected: _filter == severity,
                    onSelected: (_) => setState(() => _filter = severity),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18),
                  label: const Text('Limiares'),
                  onPressed: () => context.pushNamed(AppRoutes.thresholds),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'Nenhum alerta com a severidade "${_filter!.label}".',
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge,
                ),
              ),
            for (final alert in visible) ...[
              AlertTile(
                alert: alert,
                decision: decisions.statusFor(alert.id),
                onTap: () => context.pushNamed(
                  AppRoutes.alert,
                  pathParameters: {'alertId': alert.id},
                ),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/decisions_provider.dart';
import '../../state/notifications_provider.dart';
import '../../state/reports_provider.dart';
import '../../state/settings_provider.dart';
import '../widgets/layout.dart';

/// Preferências do app: limiares, modo offline e privacidade.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _revokeConsent(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final reports = context.read<ReportsProvider>();
    final decisions = context.read<DecisionsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revogar consentimento?'),
        content: const Text(
          'Suas ocorrências, o código anônimo e as decisões registradas serão '
          'apagados deste aparelho. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apagar e revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await reports.clearAll();
    await decisions.clearAll();
    // O roteador observa o consentimento e volta à tela inicial de aceite.
    await settings.setConsent(false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: PageBody(
          children: [
            const SectionHeader('Alertas e dados'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Limiares de alerta'),
                    subtitle: const Text('Defina quando o app deve avisar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoutes.thresholds),
                  ),
                  const Divider(),
                  const _NotificationsTile(),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.cloud_off_outlined),
                    title: const Text('Simular modo offline'),
                    subtitle: const Text(
                      'Usa só os dados salvos no aparelho, como se não '
                      'houvesse internet',
                    ),
                    value: settings.simulateOffline,
                    onChanged: settings.setSimulateOffline,
                  ),
                ],
              ),
            ),
            const SectionHeader('Privacidade'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Sobre, metodologia e privacidade'),
                    subtitle: const Text(
                      'Fontes dos dados, métricas, limitações e vieses',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoutes.about),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: context.colors.error,
                    ),
                    title: const Text('Revogar consentimento e apagar dados'),
                    subtitle: const Text(
                      'Remove ocorrências e decisões guardadas neste aparelho',
                    ),
                    onTap: () => _revokeConsent(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liga os avisos de alertas novos. A permissão do sistema só é pedida
/// quando a pessoa toca no botão, nunca ao abrir o app.
class _NotificationsTile extends StatelessWidget {
  const _NotificationsTile();

  Future<void> _toggle(BuildContext context, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<NotificationsProvider>().setEnabled(value);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de notificação negada. Libere nas configurações do '
            'aparelho para receber os avisos.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsProvider>();
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: const Text('Avisar sobre novos alertas'),
      subtitle: const Text(
        'Notificação no aparelho quando surgir um alerta de nível Alerta '
        'ou Crítico na região escolhida',
      ),
      value: notifications.enabled,
      onChanged: notifications.busy ? null : (v) => _toggle(context, v),
    );
  }
}

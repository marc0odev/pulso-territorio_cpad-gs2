import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/region.dart';
import '../../data/models/report.dart';
import '../../state/reports_provider.dart';
import '../widgets/layout.dart';
import '../widgets/state_views.dart';

/// Ocorrências registradas pelo cidadão (persistidas no aparelho).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _confirmRemoval(
    BuildContext context,
    CitizenReport report,
  ) async {
    final provider = context.read<ReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar ocorrência?'),
        content: Text(
          '"${report.category.label}" será removida deste aparelho. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.remove(report.id);
    messenger.showSnackBar(
      const SnackBar(content: Text('Ocorrência apagada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>().reports;
    if (reports.isEmpty) {
      return EmptyView(
        icon: Icons.campaign_outlined,
        title: 'Nenhuma ocorrência registrada',
        message:
            'Viu um vazamento, alagamento ou lixo acumulado? Registre '
            'aqui, sem se identificar. Os registros ajudam a conferir o que '
            'os dados mostram.',
        actionLabel: 'Registrar ocorrência',
        actionIcon: Icons.add,
        onAction: () => context.pushNamed(AppRoutes.newReport),
      );
    }
    return PageBody(
      children: [
        Text(
          'Seus registros ficam só neste aparelho, sem nome nem contato.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        for (final report in reports) ...[
          _ReportCard(
            report: report,
            onRemove: () => _confirmRemoval(context, report),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        ],
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onRemove});

  final CitizenReport report;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final region = Regions.byId(report.regionId);
    final urgencyColor = switch (report.urgency) {
      ReportUrgency.low => context.status.ok,
      ReportUrgency.medium => context.status.attention,
      ReportUrgency.high => context.status.critical,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.category.label,
                  style: context.text.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Apagar ocorrência: ${report.category.label}',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Text(report.description, style: context.text.bodyMedium),
          if (report.landmark.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Referência: ${report.landmark}',
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(icon: Icons.place_outlined, text: region.name),
              _Meta(
                icon: Icons.flag_outlined,
                text: 'Urgência ${report.urgency.label.toLowerCase()}',
                color: urgencyColor,
              ),
              _Meta(icon: Icons.schedule, text: fmtDateTime(report.createdAt)),
              _Meta(
                icon: Icons.person_off_outlined,
                text: 'Cidadão #${report.anonymousCode}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 16, color: effective)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: context.text.labelMedium?.copyWith(color: effective),
          ),
        ),
      ],
    );
  }
}

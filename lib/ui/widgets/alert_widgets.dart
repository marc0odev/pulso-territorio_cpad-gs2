import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/alert.dart';
import 'indicator_widgets.dart';
import 'layout.dart';

IconData severityIcon(AlertSeverity severity) => switch (severity) {
  AlertSeverity.attention => Icons.info_outline,
  AlertSeverity.warning => Icons.warning_amber_outlined,
  AlertSeverity.critical => Icons.report_outlined,
};

/// Selo de severidade: cor + ícone + texto (não depende só de cor).
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = context.status.forSeverity(severity);
    return Semantics(
      label: 'Severidade: ${severity.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(severityIcon(severity), size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              severity.label,
              style: context.text.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra do nível de confiança de um alerta.
class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({super.key, required this.alert, this.compact = false});

  final TerritoryAlert alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text =
        'Confiança ${alert.confidenceLabel.toLowerCase()} (${fmtPercent(alert.confidence)})';
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: compact
                ? context.text.labelMedium
                : context.text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.field),
            child: LinearProgressIndicator(
              value: alert.confidence,
              minHeight: compact ? 6 : 10,
              backgroundColor: context.colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso fixo: os alertas apoiam, mas não substituem, a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.groups_outlined,
              color: context.colors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Text(
              'Os alertas apoiam, mas não substituem, a decisão humana. '
              'Nenhuma ação é executada automaticamente: quem decide é o '
              'gestor responsável.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item de lista de alerta.
class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.decision,
    required this.onTap,
  });

  final TerritoryAlert alert;
  final DecisionStatus decision;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: context.status.forSeverity(alert.severity),
      semanticLabel:
          '${alert.severity.label}: ${alert.title}. '
          'Confiança ${alert.confidenceLabel.toLowerCase()}, '
          '${fmtPercent(alert.confidence)}. ${decision.label}. '
          'Toque para ver a justificativa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityBadge(severity: alert.severity),
              const Spacer(),
              Icon(
                indicatorIcon(alert.indicatorId),
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(alert.title, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            alert.evidence.first,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          ConfidenceMeter(alert: alert, compact: true),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                decision == DecisionStatus.pending
                    ? Icons.hourglass_empty
                    : Icons.how_to_reg_outlined,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Decisão humana: ${decision.label}',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

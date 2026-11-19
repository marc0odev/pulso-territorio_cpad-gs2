import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/alert.dart';
import '../../data/models/region.dart';
import '../../state/decisions_provider.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_widgets.dart';
import '../widgets/layout.dart';
import '../widgets/state_views.dart';
import '../widgets/territory_widgets.dart';
import 'home_shell.dart';

/// Detalhe de um alerta: evidência, confiança, limitações e o registro da
/// decisão humana. Recebe o alerta por parâmetro de rota.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: SafeArea(
        child: TerritoryStateBuilder(
          builder: (context, snapshot) {
            final alert = territory.alertById(alertId);
            if (alert == null) {
              return EmptyView(
                icon: Icons.notifications_off_outlined,
                title: 'Alerta não está mais ativo',
                message:
                    'Os dados ou os limiares mudaram e este alerta deixou '
                    'de ser gerado.',
                actionLabel: 'Ver alertas ativos',
                actionIcon: Icons.notifications_outlined,
                onAction: () => context.goNamed(
                  AppRoutes.home,
                  queryParameters: {AppRoutes.tabParam: HomeTab.alerts.slug},
                ),
              );
            }
            return _AlertContent(alert: alert);
          },
        ),
      ),
    );
  }
}

class _AlertContent extends StatelessWidget {
  const _AlertContent({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) {
    final region = Regions.byId(alert.regionId);
    return PageBody(
      children: [
        Row(
          children: [
            SeverityBadge(severity: alert.severity),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                region.name,
                style: context.text.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text(alert.title, style: context.text.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.md),
        const HumanDecisionBanner(),
        const SectionHeader('Em linguagem simples'),
        AppCard(
          color: context.brand.sun,
          child: Text(alert.plainSummary, style: context.text.bodyLarge),
        ),
        const SectionHeader(
          'Por que este alerta foi gerado',
          subtitle: 'Evidências nos dados',
        ),
        AppCard(color: context.brand.sky, child: BulletList(alert.evidence)),
        const SectionHeader('Nível de confiança'),
        AppCard(
          color: context.brand.lilac,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfidenceMeter(alert: alert),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Text(alert.confidenceReason, style: context.text.bodyMedium),
            ],
          ),
        ),
        const SectionHeader('Limitações'),
        AppCard(
          color: context.brand.peach,
          child: BulletList(alert.limitations, icon: Icons.error_outline),
        ),
        const SectionHeader('Quando NÃO confiar nesta previsão'),
        AppCard(
          color: context.brand.peach,
          child: BulletList(alert.unreliableWhen, icon: Icons.block_outlined),
        ),
        const SectionHeader(
          'Caminhos para avaliar',
          subtitle: 'Sugestões. Nada é executado pelo app.',
        ),
        AppCard(
          child: BulletList(alert.optionsForReview, icon: Icons.arrow_forward),
        ),
        const SectionHeader('Benefício social esperado'),
        AppCard(
          color: context.brand.lilac,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.volunteer_activism_outlined,
                  color: context.status.ok,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  alert.socialBenefit,
                  style: context.text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          'Decisão humana',
          subtitle: 'Registre o que o responsável decidiu',
        ),
        _DecisionForm(alertId: alert.id),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.pushNamed(
            AppRoutes.indicator,
            pathParameters: {'indicatorId': alert.indicatorId},
          ),
          icon: const Icon(Icons.show_chart),
          label: const Text('Ver os dados do indicador'),
        ),
      ],
    );
  }
}

/// Formulário de registro da decisão. O rascunho (opção marcada e texto) é
/// estado local; só vai para o estado global quando a pessoa salva.
class _DecisionForm extends StatefulWidget {
  const _DecisionForm({required this.alertId});

  final String alertId;

  @override
  State<_DecisionForm> createState() => _DecisionFormState();
}

class _DecisionFormState extends State<_DecisionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _note;
  late DecisionStatus _status;

  @override
  void initState() {
    super.initState();
    final saved = context.read<DecisionsProvider>().decisionFor(widget.alertId);
    _status = saved?.status ?? DecisionStatus.pending;
    _note = TextEditingController(text: saved?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<DecisionsProvider>().record(
      widget.alertId,
      status: _status,
      note: _note.text,
    );
    messenger.showSnackBar(
      SnackBar(content: Text('Decisão registrada: ${_status.label}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<DecisionsProvider>().decisionFor(
      widget.alertId,
    );
    final needsNote =
        _status == DecisionStatus.actionDecided ||
        _status == DecisionStatus.dismissed;
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final status in DecisionStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 240,
              decoration: InputDecoration(
                labelText: needsNote
                    ? 'Justificativa da decisão'
                    : 'Observação (opcional)',
                helperText: 'Não inclua dados pessoais.',
              ),
              validator: (value) => needsNote
                  ? Validators.lengthBetween(
                      value,
                      min: 10,
                      max: 240,
                      field: 'A justificativa',
                    )
                  : Validators.optionalMaxLength(value, max: 240),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.how_to_reg_outlined),
              label: const Text('Registrar decisão'),
            ),
            if (saved != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Último registro: ${saved.status.label}, em '
                '${fmtDateTime(saved.decidedAt)}.',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

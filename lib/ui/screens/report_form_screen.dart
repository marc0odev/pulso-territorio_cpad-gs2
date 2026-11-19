import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/anonymizer.dart';
import '../../core/utils/validators.dart';
import '../../data/models/report.dart';
import '../../state/reports_provider.dart';
import '../../state/territory_provider.dart';
import '../widgets/layout.dart';

/// Formulário de registro de ocorrência pelo cidadão, com validação campo a
/// campo. Não pede nome, contato nem localização exata.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _landmark = TextEditingController();

  ReportCategory? _category;
  late String _regionId = context.read<TerritoryProvider>().selectedRegion.id;
  ReportUrgency _urgency = ReportUrgency.medium;
  bool _saving = false;

  /// Depois da primeira tentativa de envio, valida enquanto a pessoa corrige.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _description.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revise os campos destacados antes de enviar.'),
        ),
      );
      return;
    }
    final hadPersonalData =
        Anonymizer.containsPersonalData(_description.text) ||
        Anonymizer.containsPersonalData(_landmark.text);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    await context.read<ReportsProvider>().add(
      category: _category!,
      regionId: _regionId,
      description: _description.text,
      landmark: _landmark.text,
      urgency: _urgency,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          hadPersonalData
              ? 'Ocorrência registrada. Removemos dados pessoais do texto '
                    'para proteger você.'
              : 'Ocorrência registrada. Obrigado por colaborar!',
        ),
      ),
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final regions = context.read<TerritoryProvider>().regions;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: PageBody(
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Registro anônimo. Não escreva nome, CPF, telefone ou '
                        'e-mail: se aparecerem no texto, serão removidos '
                        'automaticamente antes de salvar.',
                        style: context.text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ReportCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de ocorrência *',
                ),
                items: [
                  for (final category in ReportCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Escolha o tipo de ocorrência.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _regionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Região *',
                  helperText: 'Guardamos só a região, nunca o endereço exato.',
                ),
                items: [
                  for (final region in regions)
                    DropdownMenuItem(
                      value: region.id,
                      child: Text('${region.name} (${region.reference})'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _regionId = value ?? _regionId),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'O que está acontecendo? *',
                  hintText:
                      'Ex.: Vazamento na calçada há dois dias, a água '
                      'escorre até a esquina.',
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.lengthBetween(
                  value,
                  min: 15,
                  max: 300,
                  field: 'A descrição',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _landmark,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ponto de referência (opcional)',
                  hintText: 'Ex.: perto da praça da feira',
                ),
                validator: (value) =>
                    Validators.optionalMaxLength(value, max: 80),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Urgência', style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<ReportUrgency>(
                  segments: [
                    for (final urgency in ReportUrgency.values)
                      ButtonSegment(value: urgency, label: Text(urgency.label)),
                  ],
                  selected: {_urgency},
                  onSelectionChanged: (selection) =>
                      setState(() => _urgency = selection.first),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormField<bool>(
                initialValue: false,
                validator: (value) => value == true
                    ? null
                    : 'É preciso concordar para registrar a ocorrência.',
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: field.value,
                      onChanged: field.didChange,
                      isError: field.hasError,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Concordo que este registro anônimo seja guardado '
                        'neste aparelho e usado nos indicadores do app. *',
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Text(
                          field.errorText!,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Registrar ocorrência'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '* Campos obrigatórios',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

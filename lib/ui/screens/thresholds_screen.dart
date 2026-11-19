import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/thresholds.dart';
import '../../state/settings_provider.dart';
import '../widgets/layout.dart';

/// Descrição de um campo de limiar: evita repetir o mesmo TextFormField.
class _ThresholdField {
  const _ThresholdField({
    required this.label,
    required this.unit,
    required this.help,
    required this.min,
    required this.max,
    required this.read,
  });

  final String label;
  final String unit;
  final String help;
  final double min;
  final double max;
  final double Function(Thresholds) read;
}

/// Formulário em que o gestor define os limiares que disparam alertas.
/// Os valores são persistidos e os alertas são recalculados na hora.
class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  static final _fields = <_ThresholdField>[
    _ThresholdField(
      label: 'Consumo de água',
      unit: 'L/hab/dia',
      help: 'A ONU indica 110 L por pessoa por dia como suficiente.',
      min: 80,
      max: 400,
      read: (t) => t.water,
    ),
    _ThresholdField(
      label: 'Chuva em um dia',
      unit: 'mm',
      help:
          'Acumulados a partir de 50 mm em um dia já costumam causar '
          'transtornos.',
      min: 1,
      max: 300,
      read: (t) => t.rain,
    ),
    _ThresholdField(
      label: 'Temperatura máxima',
      unit: '°C',
      help: 'Calor a partir do qual a região deve ser avisada.',
      min: 20,
      max: 45,
      read: (t) => t.heat,
    ),
    _ThresholdField(
      label: 'Qualidade do ar (MP2,5)',
      unit: 'µg/m³',
      help: 'A OMS recomenda média diária de até 15 µg/m³.',
      min: 5,
      max: 150,
      read: (t) => t.pm25,
    ),
    _ThresholdField(
      label: 'Uso da capacidade de coleta',
      unit: '%',
      help: 'Percentual da capacidade de coleta de resíduos.',
      min: 50,
      max: 100,
      read: (t) => t.wastePercent,
    ),
    _ThresholdField(
      label: 'Crescimento semanal de chamados',
      unit: '%',
      help: 'Aumento de uma semana para a outra que merece atenção.',
      min: 5,
      max: 200,
      read: (t) => t.servicesGrowthPercent,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final current = context.read<SettingsProvider>().thresholds;
    _controllers = [
      for (final field in _fields)
        TextEditingController(text: _format(field.read(current))),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _format(double value) =>
      fmtNum(value, decimals: value == value.roundToDouble() ? 0 : 1);

  void _restoreDefaults() {
    const defaults = Thresholds();
    for (var i = 0; i < _fields.length; i++) {
      _controllers[i].text = _format(_fields[i].read(defaults));
    }
    _formKey.currentState!.validate();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final values = [
      for (final controller in _controllers)
        Validators.parseNumber(controller.text)!,
    ];
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    await context.read<SettingsProvider>().setThresholds(
      Thresholds(
        water: values[0],
        rain: values[1],
        heat: values[2],
        pm25: values[3],
        wastePercent: values[4],
        servicesGrowthPercent: values[5],
      ),
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Limiares salvos. Os alertas foram recalculados.'),
      ),
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: PageBody(
            children: [
              Text(
                'Você define a partir de que ponto o app deve avisar. Limiares '
                'mais baixos geram mais alertas (e mais alarmes falsos); mais '
                'altos geram menos alertas (e mais risco de aviso tardio).',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < _fields.length; i++) ...[
                TextFormField(
                  controller: _controllers[i],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: i == _fields.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _fields[i].label,
                    suffixText: _fields[i].unit,
                    helperText: _fields[i].help,
                  ),
                  validator: (value) => Validators.numberInRange(
                    value,
                    min: _fields[i].min,
                    max: _fields[i].max,
                    unit: _fields[i].unit,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar limiares'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _restoreDefaults,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restaurar valores padrão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

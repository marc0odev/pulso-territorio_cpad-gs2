import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../state/settings_provider.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/layout.dart';

/// Primeira tela do app: explica o que é coletado e pede consentimento
/// explícito antes de liberar qualquer funcionalidade.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  static const _commitments = [
    'O app não pede nome, CPF, e-mail nem telefone.',
    'Não usamos GPS: você escolhe a região manualmente.',
    'Ocorrências que você registrar ficam só neste aparelho, identificadas '
        'por um código aleatório.',
    'Para buscar clima e qualidade do ar, enviamos à Open-Meteo apenas as '
        'coordenadas do centro da região escolhida.',
    'Você pode apagar tudo e revogar o consentimento em Configurações.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      size: 36,
                      color: context.colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(kAppName, style: context.text.titleLarge),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const HeroHeadline(
              title: 'Cuide do seu bairro antes do problema chegar!',
              subtitle:
                  'Indicadores, previsões e alertas sobre água, energia, '
                  'clima e serviços da sua região, explicados de um jeito '
                  'simples.',
            ),
            const SectionHeader('Sua privacidade primeiro'),
            AppCard(
              color: context.brand.lilac,
              child: const BulletList(
                _commitments,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SectionHeader('Como usar as previsões'),
            AppCard(
              color: context.brand.sun,
              child: Text(
                'Parte dos dados é sintética (criada para fins acadêmicos) e '
                'toda previsão pode errar. Os alertas servem de apoio: a '
                'decisão final é sempre de uma pessoa.',
                style: context.text.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _accepted,
              onChanged: (value) => setState(() => _accepted = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Li e concordo com o uso dos dados descrito acima.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _accepted
                  ? () => context.read<SettingsProvider>().setConsent(true)
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Concordar e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

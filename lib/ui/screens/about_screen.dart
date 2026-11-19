import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/layout.dart';

/// Transparência: de onde vêm os dados, como os alertas são gerados, quais
/// métricas são usadas e em que condições as previsões não são confiáveis.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _sections = <(String, List<String>)>[
    (
      'Fontes dos dados',
      [
        'Clima e qualidade do ar: dados públicos reais da Open-Meteo '
            '(temperatura, chuva, probabilidade de precipitação e MP2,5).',
        'Água, energia, resíduos e chamados: dados SINTÉTICOS, gerados por '
            'um serviço municipal simulado. Não representam medições oficiais.',
        'Ocorrências: registradas pelos próprios cidadãos neste aparelho.',
      ],
    ),
    (
      'Como os alertas são gerados',
      [
        'Tendência: regressão linear sobre os últimos 14 dias, projetada 7 '
            'dias à frente e comparada com o limiar definido pelo gestor.',
        'Anomalia: um valor a mais de 2 desvios-padrão da média recente.',
        'Clima: previsão numérica do tempo comparada com os limiares.',
      ],
    ),
    (
      'Métricas',
      [
        'MAPE (erro percentual absoluto médio) em backtest: o modelo "prevê" '
            'os últimos 7 dias já conhecidos e medimos o quanto errou.',
        'Confiança: derivada do MAPE nas tendências; da probabilidade de '
            'chuva e da antecedência nas previsões do tempo.',
        'Índice de Bem-Estar Territorial: média das notas (0–100) dos '
            'indicadores em relação aos seus limiares.',
      ],
    ),
    (
      'Limitações e vieses',
      [
        'Modelos lineares não enxergam feriados, eventos nem mudanças bruscas.',
        'A previsão do tempo vale para um ponto de referência, não para cada '
            'rua da região.',
        'Chamados e ocorrências medem quem consegue reclamar: áreas com menos '
            'acesso digital ficam sub-representadas.',
        'Populações e capacidades usadas nos cálculos são aproximações.',
      ],
    ),
    (
      'Quando não confiar nas previsões',
      [
        'Previsões para mais de 3 dias à frente.',
        'Indicadores com menos de 14 dias de histórico.',
        'Períodos atípicos: feriados prolongados, grandes eventos, temporais.',
        'Quando o app estiver offline, exibindo dados antigos.',
      ],
    ),
    (
      'Decisão humana',
      [
        'O app não executa nenhuma ação sozinho. Os alertas trazem evidência, '
            'confiança e limitações para que o gestor decida e registre a '
            'decisão.',
      ],
    ),
    (
      'Privacidade e inclusão',
      [
        'Sem cadastro, sem nome, sem contato e sem GPS.',
        'Textos livres passam por um filtro que remove e-mail, CPF e telefone.',
        'Dados ficam apenas no aparelho e podem ser apagados a qualquer '
            'momento.',
        'Alto contraste automático quando ativado no aparelho; textos '
            'acompanham o tamanho '
            'de fonte do sistema; elementos descritos para leitores de tela.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre e metodologia')),
      body: SafeArea(
        child: PageBody(
          children: [
            Text(kAppName, style: context.text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Projeto acadêmico · FIAP · Global Solution 2026.2 · '
              'Territory Predictive Insights',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            for (final (title, items) in _sections) ...[
              SectionHeader(title),
              AppCard(child: BulletList(items)),
            ],
          ],
        ),
      ),
    );
  }
}

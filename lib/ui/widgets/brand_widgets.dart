import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/indicator.dart';
import 'layout.dart';

/// Cada painel tem um tom pastel próprio, que o usuário passa a associar ao
/// tema: céu para recursos (água/energia), sol para clima e pêssego para
/// serviços.
Color dashboardTint(BuildContext context, DashboardKind kind) => switch (kind) {
  DashboardKind.resources => context.brand.sky,
  DashboardKind.climate => context.brand.sun,
  DashboardKind.services => context.brand.peach,
};

/// Cabeçalho grande e acolhedor das telas principais.
class HeroHeadline extends StatelessWidget {
  const HeroHeadline({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.text.headlineMedium),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Selo numerado (1, 2, 3...) usado para guiar a leitura em etapas.
class NumberBadge extends StatelessWidget {
  const NumberBadge(this.number, {super.key});

  final int number;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          textScaler: TextScaler.noScaling,
          style: context.text.titleSmall?.copyWith(
            color: context.colors.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Botão redondo com contorno, para ações secundárias do cabeçalho.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size(52, 52),
        backgroundColor: filled
            ? context.colors.primary
            : context.colors.surfaceContainerLow,
        foregroundColor: filled
            ? context.colors.onPrimary
            : context.colors.onSurface,
        side: filled
            ? null
            : BorderSide(color: context.colors.outlineVariant, width: 1.5),
      ),
    );
  }
}

/// Ícone dentro de um círculo colorido (identifica indicadores e painéis).
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.background,
    this.size = 48,
  });

  final IconData icon;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? context.colors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.colors.primary, size: size * 0.5),
      ),
    );
  }
}

/// Dois números lado a lado separados por uma barra inclinada, no estilo
/// "10 dias / +15". O segundo pode ser destacado com a cor quente da marca.
class StatPair extends StatelessWidget {
  const StatPair({
    super.key,
    required this.leftValue,
    required this.leftLabel,
    required this.rightValue,
    required this.rightLabel,
    this.leftUnit,
    this.highlightRight = false,
    this.rightColor,
  });

  final String leftValue;
  final String? leftUnit;
  final String leftLabel;
  final String rightValue;
  final String rightLabel;
  final bool highlightRight;
  final Color? rightColor;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String? unit, String label, Color? color) =>
        Expanded(
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  text: value,
                  style: context.text.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        stat(leftValue, leftUnit, leftLabel, null),
        ExcludeSemantics(
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              width: 1.5,
              height: 40,
              color: context.colors.outlineVariant,
            ),
          ),
        ),
        stat(
          rightValue,
          null,
          rightLabel,
          rightColor ?? (highlightRight ? context.brand.accent : null),
        ),
      ],
    );
  }
}

/// Cartão de destaque em azul-índigo sólido com um número grande no centro.
class HeroNumberCard extends StatelessWidget {
  const HeroNumberCard({
    super.key,
    required this.number,
    required this.caption,
    required this.semanticLabel,
    this.badge,
    this.action,
    this.footnote,
    this.onInfo,
  });

  final String number;
  final String caption;
  final String semanticLabel;

  /// Pequeno destaque logo abaixo do número (ex.: "2 alertas").
  final String? badge;
  final Widget? action;
  final String? footnote;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final hc = brand.highContrast;
    return Container(
      decoration: BoxDecoration(
        color: brand.hero,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: hc
            ? Border.all(color: context.colors.outline, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Stack(
        children: [
          if (onInfo != null)
            Positioned(
              right: -8,
              top: -8,
              child: IconButton(
                tooltip: 'Como este número é calculado',
                onPressed: onInfo,
                icon: Icon(Icons.info_outline, color: brand.onHero),
              ),
            ),
          Column(
            children: [
              Semantics(
                label: semanticLabel,
                excludeSemantics: true,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Transform.translate(
                        offset: Offset(0, 12 * (1 - t)),
                        child: child,
                      ),
                      child: Text(
                        number,
                        textScaler: TextScaler.noScaling,
                        style: context.text.displayLarge?.copyWith(
                          color: brand.onHero,
                          fontWeight: FontWeight.w800,
                          fontSize: 76,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 18, color: brand.heroAccent),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              badge!,
                              style: context.text.titleSmall?.copyWith(
                                color: brand.heroAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(
                        color: brand.onHero.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(width: double.infinity, child: action),
              ],
              if (footnote != null) ...[
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: brand.onHero.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão claro usado dentro do cartão de destaque.
class HeroButton extends StatelessWidget {
  const HeroButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: context.brand.heroButton,
        foregroundColor: context.brand.onHeroButton,
      ),
    );
  }
}

/// Cartão de etapa numerada (1, 2, 3) com fundo pastel e, opcionalmente, um
/// selo de "tudo certo" no canto.
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.icon,
    this.done = false,
    this.subtitleColor,
  });

  final int number;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;
  final IconData? icon;
  final bool done;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppCard(
          color: color,
          onTap: onTap,
          semanticLabel: semanticLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NumberBadge(number),
                  const Spacer(),
                  if (icon != null)
                    ExcludeSemantics(
                      child: Icon(icon, color: context.brand.onTint),
                    ),
                  if (done) const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: context.text.titleLarge?.copyWith(
                  color: context.brand.onTint,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: context.text.bodyMedium?.copyWith(
                  color: subtitleColor ?? context.brand.onTint,
                ),
              ),
            ],
          ),
        ),
        if (done)
          Positioned(
            right: 10,
            top: 10,
            child: ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: context.status.ok,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

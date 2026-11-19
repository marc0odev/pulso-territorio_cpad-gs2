import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Cartão padrão do app: cantos bem arredondados e fundo em tom pastel.
/// Com [onTap] vira um botão acessível.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = AppSpacing.page,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsets padding;

  /// Borda colorida (usada, por exemplo, para indicar severidade).
  final Color? borderColor;

  /// Fundo do cartão; por padrão, o tom de cartão do tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder? shape = borderColor == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(color: borderColor!, width: 2),
          );
    final content = Padding(padding: padding, child: child);
    return Card(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              label: semanticLabel,
              excludeSemantics: semanticLabel != null,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.text.titleLarge),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Corpo rolável padrão das telas: margens da escala e largura máxima em
/// telas grandes. Constrói todos os filhos (não é lista preguiçosa) para que
/// campos de formulário fora da área visível continuem sendo validados.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl * 3,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
    if (onRefresh == null) return scroll;
    return RefreshIndicator(onRefresh: onRefresh!, child: scroll);
  }
}

/// Grade que se adapta à largura: 1 coluna em telas estreitas (ou com fonte
/// muito ampliada), 2 em celulares e 3+ em tablets, nunca mais colunas do que
/// itens. A altura é livre, então o
/// conteúdo nunca é cortado quando o usuário aumenta a fonte.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
  });

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm + AppSpacing.xs;
        final maxColumns = children.length.clamp(1, 4);
        final columns = (constraints.maxWidth / (minItemWidth * scale))
            .floor()
            .clamp(1, maxColumns);
        double widthFor(int count) =>
            (constraints.maxWidth - gap * (count - 1)) / count;
        // A última linha incompleta se estica para ocupar toda a largura,
        // assim a grade nunca fica com um buraco à direita.
        final remainder = children.length % columns;
        final lastRowStart = children.length - remainder;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: remainder != 0 && i >= lastRowStart
                    ? widthFor(remainder)
                    : widthFor(columns),
                child: children[i],
              ),
          ],
        );
      },
    );
  }
}

/// Linha "rótulo: valor" usada em resumos.
class LabeledValue extends StatelessWidget {
  const LabeledValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista com marcadores, usada para evidências e limitações.
class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key, this.icon = Icons.circle});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDot = icon == Icons.circle;
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: isDot ? 7 : 2,
                    right: AppSpacing.sm + AppSpacing.xs,
                    left: isDot ? AppSpacing.xs : 0,
                  ),
                  child: ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: isDot ? 6 : 18,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                Expanded(child: Text(item, style: context.text.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

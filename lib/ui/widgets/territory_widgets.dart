import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/indicator.dart';
import '../../data/models/region.dart';
import '../../data/models/territory_snapshot.dart';
import '../../state/territory_provider.dart';
import 'state_views.dart';

/// Seletor da região acompanhada (estado global).
class RegionSelector extends StatelessWidget {
  const RegionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Semantics(
      label:
          'Região selecionada: ${territory.selectedRegion.name}. '
          'Toque para trocar.',
      button: true,
      excludeSemantics: true,
      child: PopupMenuButton<Region>(
        tooltip: 'Trocar região',
        initialValue: territory.selectedRegion,
        onSelected: territory.selectRegion,
        itemBuilder: (context) => [
          for (final region in territory.regions)
            PopupMenuItem(
              value: region,
              child: Text('${region.name} (${region.reference})'),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.brand.hero,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_city, color: context.brand.onHero),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            territory.selectedRegion.name,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium,
                          ),
                        ),
                        const Icon(Icons.expand_more, size: 20),
                      ],
                    ),
                    Text(
                      'São Paulo · ${territory.selectedRegion.reference}',
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa que avisa quando os dados exibidos vieram do cache.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, required this.snapshot});

  final TerritorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isStale) return const SizedBox.shrink();
    final hasClimate = snapshot.indicators.any(
      (s) => s.origin == DataOrigin.real,
    );
    final message = snapshot.fromCache
        ? 'Sem conexão. Exibindo dados salvos em '
              '${fmtDateTime(snapshot.fetchedAt)}.'
        : hasClimate
        ? 'Clima indisponível agora. Exibindo previsão salva em '
              '${fmtDateTime(snapshot.fetchedAt)}.'
        : 'Não foi possível obter os dados de clima. Os demais painéis '
              'seguem funcionando.';
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: context.status.attention, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: context.status.attention),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(child: Text(message, style: context.text.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// Resolve os estados de carregamento e erro do território e entrega o
/// snapshot pronto para [builder]. Evita repetir essa lógica em cada tela.
class TerritoryStateBuilder extends StatelessWidget {
  const TerritoryStateBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, TerritorySnapshot snapshot)
  builder;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final snapshot = territory.snapshot;
    return switch (territory.status) {
      LoadStatus.error => ErrorView(
        message: territory.errorMessage ?? 'Erro inesperado.',
        onRetry: territory.load,
      ),
      LoadStatus.ready when snapshot != null => builder(context, snapshot),
      _ => const LoadingView(),
    };
  }
}

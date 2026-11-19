import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/alert.dart';
import '../../data/models/region.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_widgets.dart';
import 'home_shell.dart';

/// Mapa das regiões com a situação dos alertas em cada uma. Usa o centro
/// aproximado de cada região: o app não coleta a localização do usuário.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _center = LatLng(-23.57, -46.60);

  @override
  void initState() {
    super.initState();
    // Depois do primeiro frame, para não notificar ouvintes durante o build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TerritoryProvider>().loadAllRegions();
    });
  }

  AlertSeverity? _worst(List<TerritoryAlert> alerts) =>
      alerts.isEmpty ? null : alerts.first.severity;

  void _openRegion(Region region, List<TerritoryAlert> alerts, bool hasData) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(region.name, style: sheetContext.text.titleLarge),
              Text(
                'Referência: ${region.reference} · '
                '${fmtCompact(region.population)} moradores',
                style: sheetContext.text.bodyMedium?.copyWith(
                  color: sheetContext.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              if (!hasData)
                const Text('Sem dados disponíveis para esta região agora.')
              else if (alerts.isEmpty)
                const Text('Nenhum alerta ativo com os limiares atuais.')
              else
                for (final alert in alerts.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        SeverityBadge(severity: alert.severity),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(alert.title)),
                      ],
                    ),
                  ),
              if (alerts.length > 3)
                Text('e mais ${alerts.length - 3} alerta(s).'),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.read<TerritoryProvider>().selectRegion(region);
                    context.goNamed(
                      AppRoutes.home,
                      queryParameters: {
                        AppRoutes.tabParam: HomeTab.alerts.slug,
                      },
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text('Acompanhar ${region.name}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final loading = territory.allRegionsStatus == LoadStatus.loading;

    return Column(
      children: [
        if (loading)
          Semantics(
            label: 'Carregando dados de todas as regiões',
            child: const LinearProgressIndicator(),
          ),
        Expanded(
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: _center,
              initialZoom: 10.8,
              minZoom: 9,
              maxZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.fiap.gs.pulso_territorio',
              ),
              MarkerLayer(
                markers: [
                  for (final region in territory.regions)
                    Marker(
                      point: LatLng(region.latitude, region.longitude),
                      width: 132,
                      height: 76,
                      child: _RegionMarker(
                        region: region,
                        alertCount: territory.alertsFor(region.id).length,
                        worst: _worst(territory.alertsFor(region.id)),
                        hasData: territory.hasDataFor(region.id),
                        selected: region.id == territory.selectedRegion.id,
                        onTap: () => _openRegion(
                          region,
                          territory.alertsFor(region.id),
                          territory.hasDataFor(region.id),
                        ),
                      ),
                    ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
        ),
        const _MapLegend(),
      ],
    );
  }
}

class _RegionMarker extends StatelessWidget {
  const _RegionMarker({
    required this.region,
    required this.alertCount,
    required this.worst,
    required this.hasData,
    required this.selected,
    required this.onTap,
  });

  final Region region;
  final int alertCount;
  final AlertSeverity? worst;
  final bool hasData;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !hasData
        ? context.colors.outline
        : (worst == null
              ? context.status.ok
              : context.status.forSeverity(worst!));
    final situation = !hasData
        ? 'sem dados'
        : (alertCount == 0
              ? 'sem alertas'
              : '$alertCount alerta(s), o mais grave: ${worst!.label}');
    return Semantics(
      button: true,
      label: '${region.name}: $situation. Toque para ver detalhes.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: selected ? 6 : 4),
              ),
              child: hasData
                  ? Text(
                      '$alertCount',
                      style: context.text.titleMedium,
                      textScaler: TextScaler.noScaling,
                    )
                  : const Icon(Icons.question_mark, size: 18),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Text(
                region.name,
                style: context.text.labelMedium,
                textScaler: TextScaler.noScaling,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: context.text.labelMedium),
      ],
    );
    return Container(
      width: double.infinity,
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O número indica quantos alertas estão ativos em cada região.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              item(context.status.ok, 'Sem alertas'),
              for (final severity in AlertSeverity.values)
                item(context.status.forSeverity(severity), severity.label),
            ],
          ),
        ],
      ),
    );
  }
}

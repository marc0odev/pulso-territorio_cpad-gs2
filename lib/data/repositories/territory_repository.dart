import '../models/indicator.dart';
import '../models/region.dart';
import '../models/territory_snapshot.dart';
import '../services/local_store.dart';
import '../services/open_meteo_api.dart';
import '../services/simulated_city_api.dart';

class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() =>
      'Sem conexão e sem dados salvos para esta região. Conecte-se uma vez '
      'para que o app guarde os dados e funcione offline.';
}

/// Orquestra as fontes de dados e o cache. Estratégia "rede primeiro, cache
/// como reserva": cada carga bem-sucedida é salva e reutilizada sem conexão.
class TerritoryRepository {
  TerritoryRepository({
    required this.store,
    required this.cityApi,
    required this.climateApi,
  });

  final LocalStore store;
  final SimulatedCityApi cityApi;
  final OpenMeteoApi climateApi;

  TerritorySnapshot? readCache(String regionId) {
    final json = store.readJson(LocalStore.snapshotKey(regionId));
    if (json is! Map<String, dynamic>) return null;
    try {
      return TerritorySnapshot.fromJson(json);
    } on Object {
      return null; // cache de versão antiga ou corrompido: ignora
    }
  }

  Future<TerritorySnapshot> load(Region region, {bool offline = false}) async {
    final cached = readCache(region.id);

    if (offline) {
      if (cached == null) throw const OfflineException();
      return cached.copyWith(fromCache: true);
    }

    final city = await cityApi.fetch(region);

    // O clima depende da internet: se falhar, reaproveita o que houver salvo.
    List<IndicatorSeries> climate;
    var climateFromCache = false;
    try {
      climate = await climateApi.fetchClimate(region);
    } on Object {
      climate = cached?.byDashboard(DashboardKind.climate) ?? const [];
      climateFromCache = true;
    }

    final snapshot = TerritorySnapshot(
      regionId: region.id,
      fetchedAt: climateFromCache && cached != null
          ? cached.fetchedAt
          : DateTime.now(),
      indicators: [...city.indicators, ...climate],
      serviceBreakdown: city.serviceBreakdown,
      climateFromCache: climateFromCache,
    );
    if (!climateFromCache) {
      await store.writeJson(
        LocalStore.snapshotKey(region.id),
        snapshot.toJson(),
      );
    }
    return snapshot;
  }
}

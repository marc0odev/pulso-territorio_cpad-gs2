import 'package:flutter/foundation.dart';

import '../data/models/alert.dart';
import '../data/models/region.dart';
import '../data/models/territory_snapshot.dart';
import '../data/models/thresholds.dart';
import '../data/repositories/territory_repository.dart';
import '../data/services/local_store.dart';
import '../domain/alert_engine.dart';
import '../domain/social_impact.dart';
import 'settings_provider.dart';

enum LoadStatus { idle, loading, ready, error }

/// Estado global do território: região selecionada, dados carregados e
/// alertas derivados. É consumido por praticamente todas as telas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider({
    required this._repository,
    required this._store,
    required this._settings,
    this._engine = const AlertEngine(),
    this._impactCalculator = const SocialImpactCalculator(),
  }) {
    _selected = Regions.byId(_store.readString(LocalStore.regionKey));
    _thresholds = _settings.thresholds;
    _offline = _settings.simulateOffline;
    _settings.addListener(_onSettingsChanged);
  }

  final TerritoryRepository _repository;
  final LocalStore _store;
  final SettingsProvider _settings;
  final AlertEngine _engine;
  final SocialImpactCalculator _impactCalculator;

  late Region _selected;
  late Thresholds _thresholds;
  late bool _offline;

  final Map<String, TerritorySnapshot> _snapshots = {};
  final Map<String, List<TerritoryAlert>> _alertCache = {};

  LoadStatus _status = LoadStatus.idle;
  LoadStatus _allRegionsStatus = LoadStatus.idle;
  String? _errorMessage;

  List<Region> get regions => Regions.all;
  Region get selectedRegion => _selected;
  LoadStatus get status => _status;
  LoadStatus get allRegionsStatus => _allRegionsStatus;
  String? get errorMessage => _errorMessage;
  TerritorySnapshot? get snapshot => _snapshots[_selected.id];
  List<TerritoryAlert> get alerts => alertsFor(_selected.id);

  bool hasDataFor(String regionId) => _snapshots.containsKey(regionId);

  /// Alertas de uma região, recalculados só quando dados ou limiares mudam.
  List<TerritoryAlert> alertsFor(String regionId) {
    final snapshot = _snapshots[regionId];
    if (snapshot == null) return const [];
    return _alertCache.putIfAbsent(
      regionId,
      () => _engine.evaluate(
        region: Regions.byId(regionId),
        snapshot: snapshot,
        thresholds: _thresholds,
      ),
    );
  }

  TerritoryAlert? alertById(String id) {
    for (final regionId in _snapshots.keys) {
      for (final alert in alertsFor(regionId)) {
        if (alert.id == id) return alert;
      }
    }
    return null;
  }

  SocialImpact? get socialImpact {
    final current = snapshot;
    if (current == null) return null;
    return _impactCalculator.compute(
      region: _selected,
      snapshot: current,
      thresholds: _thresholds,
    );
  }

  Future<void> selectRegion(Region region) async {
    if (region.id == _selected.id) return;
    _selected = region;
    await _store.writeString(LocalStore.regionKey, region.id);
    await load();
  }

  /// Carrega (ou recarrega) os dados da região selecionada.
  Future<void> load() async {
    final region = _selected;
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.load(region, offline: _offline);
      _snapshots[region.id] = snapshot;
      _alertCache.remove(region.id);
      if (region.id != _selected.id) return; // usuário trocou de região
      _status = LoadStatus.ready;
    } on Object catch (error) {
      if (region.id != _selected.id) return;
      _snapshots.remove(region.id);
      _status = LoadStatus.error;
      _errorMessage = error is OfflineException
          ? error.toString()
          : 'Não foi possível carregar os dados da região. Tente novamente.';
    }
    notifyListeners();
  }

  /// Carrega todas as regiões (usado pelo mapa). Falhas individuais não
  /// derrubam o conjunto: a região apenas fica sem dados.
  Future<void> loadAllRegions() async {
    if (_allRegionsStatus == LoadStatus.loading) return;
    _allRegionsStatus = LoadStatus.loading;
    notifyListeners();
    await Future.wait([
      for (final region in regions)
        if (!_snapshots.containsKey(region.id))
          _repository
              .load(region, offline: _offline)
              .then<void>(
                (snapshot) => _snapshots[region.id] = snapshot,
                onError: (Object _) {},
              ),
    ]);
    _allRegionsStatus = LoadStatus.ready;
    notifyListeners();
  }

  void _onSettingsChanged() {
    if (!identical(_settings.thresholds, _thresholds)) {
      _thresholds = _settings.thresholds;
      _alertCache.clear();
      notifyListeners();
    }
    if (_settings.simulateOffline != _offline) {
      _offline = _settings.simulateOffline;
      _snapshots.clear();
      _alertCache.clear();
      _allRegionsStatus = LoadStatus.idle;
      load();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../data/models/thresholds.dart';
import '../data/services/local_store.dart';

/// Estado global de preferências: consentimento, limiares de alerta e modo
/// offline simulado. Tudo (exceto o modo offline) é persistido.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._store) {
    _consentGiven = _store.readBool(LocalStore.consentKey);
    final json = _store.readJson(LocalStore.thresholdsKey);
    _thresholds = json is Map<String, dynamic>
        ? Thresholds.fromJson(json)
        : const Thresholds();
  }

  final LocalStore _store;

  late bool _consentGiven;
  late Thresholds _thresholds;
  bool _simulateOffline = false;

  bool get consentGiven => _consentGiven;
  Thresholds get thresholds => _thresholds;

  /// Permite demonstrar o funcionamento sem conexão sem desligar a rede.
  bool get simulateOffline => _simulateOffline;

  Future<void> setConsent(bool value) async {
    _consentGiven = value;
    notifyListeners();
    await _store.writeBool(LocalStore.consentKey, value);
  }

  Future<void> setThresholds(Thresholds thresholds) async {
    _thresholds = thresholds;
    notifyListeners();
    await _store.writeJson(LocalStore.thresholdsKey, thresholds.toJson());
  }

  void setSimulateOffline(bool value) {
    _simulateOffline = value;
    notifyListeners();
  }
}

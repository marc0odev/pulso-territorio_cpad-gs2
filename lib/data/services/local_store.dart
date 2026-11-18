import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local (chave → JSON) sobre o SharedPreferences.
/// Centraliza as chaves para que nenhuma tela acesse o armazenamento direto.
class LocalStore {
  const LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const consentKey = 'consent_given';
  static const thresholdsKey = 'thresholds';
  static const regionKey = 'selected_region';
  static const reportsKey = 'citizen_reports';
  static const decisionsKey = 'alert_decisions';
  static const anonymousCodeKey = 'anonymous_code';
  static const notificationsKey = 'notifications_enabled';
  static const notifiedAlertsKey = 'notified_alerts';
  static String snapshotKey(String regionId) => 'snapshot_$regionId';

  bool readBool(String key) => _prefs.getBool(key) ?? false;
  Future<void> writeBool(String key, bool value) => _prefs.setBool(key, value);

  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  /// Devolve `null` se a chave não existir ou o conteúdo estiver corrompido.
  dynamic readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);
}

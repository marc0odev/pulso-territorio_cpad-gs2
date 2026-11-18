import 'package:flutter/foundation.dart';

import '../data/models/alert.dart';
import '../data/services/alert_notifier.dart';
import '../data/services/local_store.dart';
import 'territory_provider.dart';

/// Observa os alertas da região selecionada e avisa por notificação local
/// quando surge um alerta novo (ou quando um alerta sobe de nível).
///
/// É opcional e desligado por padrão: só começa depois que a pessoa ativa nas
/// configurações e o sistema concede a permissão. Avisos de "Atenção" não
/// geram notificação, para não cansar quem usa. O aviso só informa: nenhuma
/// ação é tomada sem decisão humana.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    required this._store,
    required this._territory,
    required this._notifier,
    required this._onOpenAlert,
  }) {
    _enabled = _store.readBool(LocalStore.notificationsKey);
    final saved = _store.readJson(LocalStore.notifiedAlertsKey);
    if (saved is List) _notified.addAll(saved.whereType<String>());
    _territory.addListener(_checkAlerts);
    if (_enabled) _notifier.init(onOpen: _onOpenAlert);
  }

  final LocalStore _store;
  final TerritoryProvider _territory;
  final AlertNotifier _notifier;
  final void Function(String alertId) _onOpenAlert;

  /// Chaves `idDoAlerta:nivel` já avisadas.
  final Set<String> _notified = {};
  late bool _enabled;
  bool _busy = false;

  bool get enabled => _enabled;
  bool get busy => _busy;

  static String _key(TerritoryAlert alert) =>
      '${alert.id}:${alert.severity.name}';

  static bool _worthNotifying(TerritoryAlert alert) =>
      alert.severity != AlertSeverity.attention;

  /// Liga ou desliga os avisos. Devolve `false` se o sistema negou a
  /// permissão (a opção continua desligada).
  Future<bool> setEnabled(bool value) async {
    if (value == _enabled || _busy) return true;
    if (!value) {
      _enabled = false;
      notifyListeners();
      await _store.writeBool(LocalStore.notificationsKey, false);
      return true;
    }

    _busy = true;
    notifyListeners();
    await _notifier.init(onOpen: _onOpenAlert);
    final granted = await _notifier.requestPermission();
    _busy = false;
    if (!granted) {
      notifyListeners();
      return false;
    }
    // Os alertas que já estão na tela não viram notificação: o aviso é só
    // para o que aparecer daqui em diante.
    for (final alert in _territory.alerts) {
      _notified.add(_key(alert));
    }
    _enabled = true;
    notifyListeners();
    await _store.writeBool(LocalStore.notificationsKey, true);
    await _persist();
    return true;
  }

  void _checkAlerts() {
    if (!_enabled || _territory.status != LoadStatus.ready) return;
    final region = _territory.selectedRegion;
    final active = _territory.alerts.where(_worthNotifying).toList();
    final activeKeys = {for (final alert in active) _key(alert)};

    // Alerta que deixou de existir pode avisar de novo se voltar.
    final before = _notified.length;
    _notified.removeWhere(
      (key) => key.startsWith('${region.id}-') && !activeKeys.contains(key),
    );
    var changed = _notified.length != before;

    for (final alert in active) {
      if (_notified.add(_key(alert))) {
        changed = true;
        _notifier.show(alert, regionName: region.name);
      }
    }
    if (changed) _persist();
  }

  Future<void> _persist() =>
      _store.writeJson(LocalStore.notifiedAlertsKey, _notified.toList());

  @override
  void dispose() {
    _territory.removeListener(_checkAlerts);
    super.dispose();
  }
}

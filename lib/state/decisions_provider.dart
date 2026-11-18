import 'package:flutter/foundation.dart';

import '../data/models/alert.dart';
import '../data/services/local_store.dart';

/// Estado global das decisões humanas sobre os alertas. O app nunca age
/// sozinho: aqui fica apenas o registro do que uma pessoa decidiu.
class DecisionsProvider extends ChangeNotifier {
  DecisionsProvider(this._store) {
    final json = _store.readJson(LocalStore.decisionsKey);
    if (json is Map<String, dynamic>) {
      json.forEach((alertId, value) {
        _decisions[alertId] = AlertDecision.fromJson(
          value as Map<String, dynamic>,
        );
      });
    }
  }

  final LocalStore _store;
  final Map<String, AlertDecision> _decisions = {};

  AlertDecision? decisionFor(String alertId) => _decisions[alertId];

  DecisionStatus statusFor(String alertId) =>
      _decisions[alertId]?.status ?? DecisionStatus.pending;

  Future<void> record(
    String alertId, {
    required DecisionStatus status,
    required String note,
  }) async {
    _decisions[alertId] = AlertDecision(
      status: status,
      note: note.trim(),
      decidedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _decisions.clear();
    notifyListeners();
    await _store.remove(LocalStore.decisionsKey);
  }

  Future<void> _persist() => _store.writeJson(
    LocalStore.decisionsKey,
    _decisions.map((id, decision) => MapEntry(id, decision.toJson())),
  );
}

import 'package:flutter/foundation.dart';

import '../core/utils/anonymizer.dart';
import '../data/models/report.dart';
import '../data/services/local_store.dart';

/// Estado global das ocorrências registradas pelo cidadão neste aparelho.
/// Os registros ficam somente no dispositivo e sem identificação pessoal.
class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this._store) {
    final json = _store.readJson(LocalStore.reportsKey);
    if (json is List) {
      _reports.addAll([
        for (final item in json)
          CitizenReport.fromJson(item as Map<String, dynamic>),
      ]);
    }
  }

  final LocalStore _store;
  final List<CitizenReport> _reports = [];

  /// Mais recentes primeiro.
  List<CitizenReport> get reports => List.unmodifiable(_reports);

  int countForRegion(String regionId) =>
      _reports.where((r) => r.regionId == regionId).length;

  /// Código aleatório do aparelho, criado no primeiro registro.
  Future<String> _anonymousCode() async {
    var code = _store.readString(LocalStore.anonymousCodeKey);
    if (code == null) {
      code = Anonymizer.randomCode();
      await _store.writeString(LocalStore.anonymousCodeKey, code);
    }
    return code;
  }

  Future<CitizenReport> add({
    required ReportCategory category,
    required String regionId,
    required String description,
    required String landmark,
    required ReportUrgency urgency,
  }) async {
    final now = DateTime.now();
    final report = CitizenReport(
      id: now.microsecondsSinceEpoch.toString(),
      anonymousCode: await _anonymousCode(),
      category: category,
      regionId: regionId,
      // Remove e-mail, CPF e telefone digitados por engano antes de salvar.
      description: Anonymizer.redact(description),
      landmark: Anonymizer.redact(landmark),
      urgency: urgency,
      createdAt: now,
    );
    _reports.insert(0, report);
    notifyListeners();
    await _persist();
    return report;
  }

  Future<void> remove(String id) async {
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
    await _persist();
  }

  /// Apaga todas as ocorrências e o código anônimo (revogação do consentimento).
  Future<void> clearAll() async {
    _reports.clear();
    notifyListeners();
    await _store.remove(LocalStore.reportsKey);
    await _store.remove(LocalStore.anonymousCodeKey);
  }

  Future<void> _persist() => _store.writeJson(LocalStore.reportsKey, [
    for (final r in _reports) r.toJson(),
  ]);
}

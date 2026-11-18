enum ReportCategory {
  waterLeak('Vazamento de água'),
  powerOutage('Falta de energia ou iluminação'),
  flooding('Alagamento'),
  waste('Lixo ou entulho acumulado'),
  airQuality('Fumaça ou qualidade do ar'),
  other('Outro');

  const ReportCategory(this.label);
  final String label;
}

enum ReportUrgency {
  low('Baixa'),
  medium('Média'),
  high('Alta');

  const ReportUrgency(this.label);
  final String label;
}

/// Ocorrência registrada pelo cidadão. Não guarda nome, contato nem
/// localização exata: apenas um código anônimo e a região.
class CitizenReport {
  const CitizenReport({
    required this.id,
    required this.anonymousCode,
    required this.category,
    required this.regionId,
    required this.description,
    required this.landmark,
    required this.urgency,
    required this.createdAt,
  });

  final String id;
  final String anonymousCode;
  final ReportCategory category;
  final String regionId;
  final String description;
  final String landmark;
  final ReportUrgency urgency;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'anonymousCode': anonymousCode,
    'category': category.name,
    'regionId': regionId,
    'description': description,
    'landmark': landmark,
    'urgency': urgency.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CitizenReport.fromJson(Map<String, dynamic> json) => CitizenReport(
    id: json['id'] as String,
    anonymousCode: json['anonymousCode'] as String,
    category: ReportCategory.values.byName(json['category'] as String),
    regionId: json['regionId'] as String,
    description: json['description'] as String,
    landmark: json['landmark'] as String? ?? '',
    urgency: ReportUrgency.values.byName(json['urgency'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

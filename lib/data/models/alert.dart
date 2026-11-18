enum AlertSeverity {
  attention('Atenção'),
  warning('Alerta'),
  critical('Crítico');

  const AlertSeverity(this.label);
  final String label;

  /// Classifica pela razão entre o valor esperado e o limiar.
  static AlertSeverity fromRatio(double ratio) {
    if (ratio >= 1.2) return critical;
    if (ratio >= 1.05) return warning;
    return attention;
  }
}

/// Alerta preditivo. Todo alerta carrega a evidência que o gerou, o nível de
/// confiança e suas limitações: ele apoia, mas nunca substitui, a decisão
/// humana.
class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.regionId,
    required this.indicatorId,
    required this.title,
    required this.plainSummary,
    required this.severity,
    required this.evidence,
    required this.confidence,
    required this.confidenceReason,
    required this.limitations,
    required this.unreliableWhen,
    required this.optionsForReview,
    required this.socialBenefit,
  });

  /// Estável entre atualizações: `regiao-regra`.
  final String id;
  final String regionId;
  final String indicatorId;
  final String title;

  /// Explicação em linguagem simples para o cidadão.
  final String plainSummary;
  final AlertSeverity severity;

  /// Justificativa: os números que dispararam o alerta.
  final List<String> evidence;

  /// 0 a 1.
  final double confidence;
  final String confidenceReason;
  final List<String> limitations;
  final List<String> unreliableWhen;

  /// Encaminhamentos possíveis para o gestor avaliar (nunca automáticos).
  final List<String> optionsForReview;
  final String socialBenefit;

  String get confidenceLabel {
    if (confidence >= 0.8) return 'Alta';
    if (confidence >= 0.6) return 'Média';
    return 'Baixa';
  }
}

enum DecisionStatus {
  pending('Aguardando análise'),
  inReview('Em análise'),
  actionDecided('Ação decidida'),
  dismissed('Descartado');

  const DecisionStatus(this.label);
  final String label;
}

/// Registro da decisão tomada por uma pessoa a respeito de um alerta.
class AlertDecision {
  const AlertDecision({
    required this.status,
    required this.note,
    required this.decidedAt,
  });

  final DecisionStatus status;
  final String note;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'note': note,
    'decidedAt': decidedAt.toIso8601String(),
  };

  factory AlertDecision.fromJson(Map<String, dynamic> json) => AlertDecision(
    status: DecisionStatus.values.byName(json['status'] as String),
    note: json['note'] as String? ?? '',
    decidedAt: DateTime.parse(json['decidedAt'] as String),
  );
}

import 'dart:math';

import '../core/utils/formatters.dart';
import '../core/utils/stats.dart';
import '../data/models/alert.dart';
import '../data/models/indicator.dart';
import '../data/models/region.dart';
import '../data/models/territory_snapshot.dart';
import '../data/models/thresholds.dart';
import 'social_impact.dart';

/// Gera alertas preditivos a partir dos dados e dos limiares definidos pelo
/// gestor. É uma função pura (mesma entrada → mesma saída), o que a torna
/// auditável e fácil de testar.
///
/// O motor apenas SINALIZA: ele não executa nenhuma ação. Todo alerta leva
/// evidência, confiança e limitações para que uma pessoa decida.
class AlertEngine {
  const AlertEngine();

  static const _syntheticLimitation =
      'Baseado em dados sintéticos gerados para fins acadêmicos: não '
      'representa medições oficiais da região.';
  static const _linearLimitation =
      'A projeção linear assume que a tendência recente continua; ela não '
      'enxerga feriados, eventos ou mudanças bruscas de comportamento.';

  List<TerritoryAlert> evaluate({
    required Region region,
    required TerritorySnapshot snapshot,
    required Thresholds thresholds,
  }) {
    final alerts =
        <TerritoryAlert?>[
          _water(region, snapshot, thresholds),
          _energy(region, snapshot),
          _rain(region, snapshot, thresholds),
          _heat(region, snapshot, thresholds),
          _air(region, snapshot, thresholds),
          _waste(region, snapshot, thresholds),
          _services(region, snapshot, thresholds),
        ].nonNulls.toList()..sort((a, b) {
          final bySeverity = b.severity.index.compareTo(a.severity.index);
          return bySeverity != 0
              ? bySeverity
              : b.confidence.compareTo(a.confidence);
        });
    return alerts;
  }

  /// Confiança de uma projeção de tendência, derivada do erro no backtest:
  /// MAPE de 5% → 0,90; 10% → 0,80; 20% → 0,60.
  static double trendConfidence(double? mape) {
    if (mape == null) return 0.5;
    return (1 - 2 * mape).clamp(0.35, 0.9);
  }

  /// A confiança de previsões do tempo cai com a distância até o dia previsto.
  static double leadTimeFactor(int daysAhead) {
    if (daysAhead <= 1) return 1;
    if (daysAhead <= 3) return 0.9;
    return 0.75;
  }

  static String _id(Region region, String rule) => '${region.id}-$rule';

  static String _mapeText(IndicatorSeries s) => s.backtestMape == null
      ? 'Histórico insuficiente para medir o erro do modelo.'
      : 'Erro médio do modelo ao reprever os últimos 7 dias (MAPE): '
            '${fmtPercent(s.backtestMape!, decimals: 1)}.';

  static String _trendConfidenceReason(IndicatorSeries s) =>
      s.backtestMape == null
      ? 'Confiança padrão: não há histórico suficiente para o backtest.'
      : 'Calculada a partir do backtest: o modelo errou em média '
            '${fmtPercent(s.backtestMape!, decimals: 1)} ao reprever a '
            'última semana. Quanto menor o erro, maior a confiança.';

  static DataPoint _peak(List<DataPoint> points) =>
      points.reduce((a, b) => a.value >= b.value ? a : b);

  static int _daysAhead(DataPoint point) =>
      point.date.difference(dateOnly(DateTime.now())).inDays;

  TerritoryAlert? _water(Region region, TerritorySnapshot s, Thresholds t) {
    final series = s.indicator(IndicatorIds.water);
    if (series == null ||
        series.history.length < 14 ||
        series.forecast.isEmpty) {
      return null;
    }
    final average = series.lastWeekAverage!;
    final peak = _peak(series.forecast);
    final alreadyAbove = average >= t.water;
    if (!alreadyAbove && peak.value < t.water) return null;

    final worst = max(average, peak.value);
    final crossing = series.forecast.firstWhere(
      (p) => p.value >= t.water,
      orElse: () => peak,
    );
    final excess = (worst - t.water) * region.population;
    final people = (excess / SocialImpactCalculator.unWaterReference).round();

    return TerritoryAlert(
      id: _id(region, 'agua'),
      regionId: region.id,
      indicatorId: series.id,
      title: alreadyAbove
          ? 'Consumo de água acima do limiar'
          : 'Consumo de água deve ultrapassar o limiar em ${fmtDate(crossing.date)}',
      plainSummary: alreadyAbove
          ? 'A região está usando mais água por pessoa do que o limite '
                'definido. Se continuar assim, o abastecimento pode ficar '
                'pressionado.'
          : 'O uso de água vem subindo e, mantido o ritmo, passa do limite '
                'definido nos próximos dias.',
      severity: AlertSeverity.fromRatio(worst / t.water),
      evidence: [
        'Média dos últimos 7 dias: ${fmtNum(average)} ${series.unit} '
            '(limiar: ${fmtNum(t.water, decimals: 0)}).',
        'Pico projetado: ${fmtNum(peak.value)} ${series.unit} em '
            '${fmtDate(peak.date)}.',
        if (series.weeklyTrendPercent != null)
          'Variação semanal: ${fmtSignedPercent(series.weeklyTrendPercent!)} '
              'em relação à semana anterior.',
        _mapeText(series),
      ],
      confidence: trendConfidence(series.backtestMape),
      confidenceReason: _trendConfidenceReason(series),
      limitations: const [_syntheticLimitation, _linearLimitation],
      unreliableWhen: const [
        'Houve feriado prolongado, evento de grande porte ou onda de calor '
            'na janela analisada.',
        'A rede teve manutenção ou vazamento que distorceu as medições.',
        'Há menos de 14 dias de histórico disponível.',
      ],
      optionsForReview: const [
        'Verificar com a concessionária se há vazamentos na rede.',
        'Avaliar campanha de uso consciente nos bairros com maior consumo.',
        'Acompanhar o indicador por mais alguns dias antes de agir.',
      ],
      socialBenefit:
          'Trazer o consumo de volta ao limiar pouparia cerca de '
          '${fmtCompact(excess)} litros por dia, o suficiente para abastecer '
          '${fmtCompact(people)} pessoas (referência ONU de 110 L/pessoa/dia).',
    );
  }

  TerritoryAlert? _energy(Region region, TerritorySnapshot s) {
    final series = s.indicator(IndicatorIds.energy);
    if (series == null || series.history.length < 15) return null;
    final values = series.historyValues;
    final baseline = values.sublist(0, values.length - 1);
    final z = Stats.zScore(values.last, baseline);
    if (z < Thresholds.energyZScore) return null;

    final mean = Stats.mean(baseline);
    return TerritoryAlert(
      id: _id(region, 'energia'),
      regionId: region.id,
      indicatorId: series.id,
      title: 'Pico atípico no consumo de energia',
      plainSummary:
          'O consumo de energia de ontem para hoje ficou bem acima '
          'do normal para a região. Pode ser calor, um evento ou um problema '
          'na medição.',
      severity: z >= 4
          ? AlertSeverity.critical
          : (z >= 3 ? AlertSeverity.warning : AlertSeverity.attention),
      evidence: [
        'Último valor: ${fmtNum(values.last, decimals: 2)} ${series.unit}.',
        'Média dos ${baseline.length} dias anteriores: '
            '${fmtNum(mean, decimals: 2)} ${series.unit}.',
        'Desvio: ${fmtNum(z)} desvios-padrão acima da média '
            '(regra dispara a partir de '
            '${fmtNum(Thresholds.energyZScore, decimals: 0)}).',
      ],
      confidence: (0.5 + (z - Thresholds.energyZScore) * 0.1).clamp(0.5, 0.85),
      confidenceReason:
          'Cresce com a distância do valor em relação ao padrão '
          'histórico. Um único dia fora da curva tem confiança limitada: pode '
          'ser ruído ou erro de leitura.',
      limitations: const [
        _syntheticLimitation,
        'Detecção de anomalia por desvio-padrão: aponta que algo fugiu do '
            'padrão, mas não explica a causa.',
      ],
      unreliableWhen: const [
        'O dia analisado foi atípico por motivo conhecido (feriado, evento, '
            'onda de calor).',
        'Houve falha ou atraso na leitura dos medidores.',
      ],
      optionsForReview: const [
        'Conferir com a distribuidora se houve erro de leitura.',
        'Verificar se há previsão de calor que explique o uso de '
            'ar-condicionado.',
        'Aguardar a leitura de amanhã para confirmar se o pico persiste.',
      ],
      socialBenefit:
          'Identificar cedo a sobrecarga ajuda a prevenir quedas '
          'de energia que afetam principalmente quem depende de equipamentos '
          'médicos em casa.',
    );
  }

  TerritoryAlert? _rain(Region region, TerritorySnapshot s, Thresholds t) {
    final series = s.indicator(IndicatorIds.rain);
    if (series == null || series.forecast.isEmpty) return null;
    final peak = _peak(series.forecast);
    if (peak.value < t.rain) return null;

    final index = series.forecast.indexOf(peak);
    final probability =
        series.forecastProbability != null &&
            index < series.forecastProbability!.length
        ? series.forecastProbability![index]
        : 50.0;
    final daysAhead = _daysAhead(peak);
    final wetDays = series.forecast.where((p) => p.value >= t.rain).length;

    return TerritoryAlert(
      id: _id(region, 'chuva'),
      regionId: region.id,
      indicatorId: series.id,
      title: 'Chuva forte prevista para ${fmtDate(peak.date)}',
      plainSummary:
          'A previsão indica muita chuva em um único dia. Áreas '
          'baixas e próximas a córregos podem alagar.',
      severity: AlertSeverity.fromRatio(peak.value / t.rain),
      evidence: [
        'Chuva prevista: ${fmtNum(peak.value)} mm em ${fmtDate(peak.date)} '
            '(limiar: ${fmtNum(t.rain, decimals: 0)} mm/dia).',
        'Probabilidade de precipitação no dia: ${fmtNum(probability, decimals: 0)}%.',
        'Dias com chuva acima do limiar nos próximos 7 dias: $wetDays.',
        'Antecedência da previsão: $daysAhead dia(s).',
      ],
      confidence: (probability / 100 * leadTimeFactor(daysAhead)).clamp(
        0.3,
        0.9,
      ),
      confidenceReason:
          'Probabilidade de chuva informada pelo modelo '
          'meteorológico, reduzida conforme a previsão fica mais distante.',
      limitations: const [
        'A previsão vale para um ponto de referência da região; pancadas '
            'localizadas podem ser bem diferentes de um bairro para outro.',
        'O volume diário não mostra a intensidade por hora, que é o que mais '
            'pesa nos alagamentos.',
        'O app não considera drenagem, relevo nem ocupação do solo.',
      ],
      unreliableWhen: const [
        'A previsão é para mais de 3 dias à frente.',
        'Há sistemas convectivos de verão (temporais isolados), difíceis de '
            'prever com precisão.',
      ],
      optionsForReview: const [
        'Consultar os avisos oficiais da Defesa Civil e do INMET.',
        'Avaliar a limpeza preventiva de bocas de lobo em pontos críticos.',
        'Avaliar comunicação antecipada aos moradores de áreas de risco.',
      ],
      socialBenefit:
          'Antecipar a chuva forte dá tempo para proteger famílias '
          'em áreas de risco entre os ${fmtCompact(region.population)} '
          'moradores da região.',
    );
  }

  TerritoryAlert? _heat(Region region, TerritorySnapshot s, Thresholds t) {
    final series = s.indicator(IndicatorIds.tempMax);
    if (series == null || series.forecast.isEmpty) return null;
    final peak = _peak(series.forecast);
    if (peak.value < t.heat) return null;

    final hotDays = series.forecast.where((p) => p.value >= t.heat).length;
    final daysAhead = _daysAhead(peak);
    return TerritoryAlert(
      id: _id(region, 'calor'),
      regionId: region.id,
      indicatorId: series.id,
      title: 'Calor intenso previsto para ${fmtDate(peak.date)}',
      plainSummary:
          'Os próximos dias devem ser muito quentes. Idosos, '
          'crianças e quem trabalha na rua sofrem mais com o calor.',
      severity: hotDays >= 3
          ? AlertSeverity.critical
          : AlertSeverity.fromRatio(peak.value / t.heat),
      evidence: [
        'Máxima prevista: ${fmtNum(peak.value)} °C em ${fmtDate(peak.date)} '
            '(limiar: ${fmtNum(t.heat, decimals: 0)} °C).',
        'Dias acima do limiar nos próximos 7 dias: $hotDays.',
        if (series.lastWeekAverage != null)
          'Média das máximas na última semana: '
              '${fmtNum(series.lastWeekAverage!)} °C.',
      ],
      confidence: (0.88 * leadTimeFactor(daysAhead)).clamp(0.3, 0.9),
      confidenceReason:
          'Previsões de temperatura costumam ser confiáveis '
          'para os primeiros dias e perdem precisão com a distância.',
      limitations: const [
        'Temperatura do ar em um ponto de referência: não considera ilhas '
            'de calor, umidade nem sensação térmica.',
        'Ruas sem arborização podem ficar vários graus acima do previsto.',
      ],
      unreliableWhen: const [
        'A previsão é para mais de 3 dias à frente.',
        'Há passagem de frente fria prevista, que muda o cenário rapidamente.',
      ],
      optionsForReview: const [
        'Avaliar ampliar pontos de hidratação e abrigos climatizados.',
        'Avaliar orientação a unidades de saúde e escolas.',
        'Acompanhar a atualização da previsão nas próximas 24 horas.',
      ],
      socialBenefit:
          'Avisos antecipados de calor reduzem atendimentos por '
          'desidratação e protegem os grupos mais vulneráveis.',
    );
  }

  TerritoryAlert? _air(Region region, TerritorySnapshot s, Thresholds t) {
    final series = s.indicator(IndicatorIds.pm25);
    if (series == null || series.forecast.isEmpty) return null;
    final peak = _peak(series.forecast);
    if (peak.value < t.pm25) return null;

    final badDays = series.forecast.where((p) => p.value >= t.pm25).length;
    return TerritoryAlert(
      id: _id(region, 'ar'),
      regionId: region.id,
      indicatorId: series.id,
      title: 'Qualidade do ar deve piorar em ${fmtDate(peak.date)}',
      plainSummary:
          'A quantidade de poeira fina no ar deve passar do nível '
          'recomendado. Pessoas com asma ou bronquite podem sentir mais.',
      // Faixas das metas intermediárias da OMS para MP2,5 em 24 h.
      severity: peak.value >= 37.5
          ? AlertSeverity.critical
          : (peak.value >= 25
                ? AlertSeverity.warning
                : AlertSeverity.attention),
      evidence: [
        'MP2,5 previsto: ${fmtNum(peak.value)} µg/m³ (média diária) em '
            '${fmtDate(peak.date)}; limiar: ${fmtNum(t.pm25, decimals: 0)} µg/m³.',
        'Dias acima do limiar na previsão: $badDays de ${series.forecast.length}.',
        if (series.lastWeekAverage != null)
          'Média da última semana: ${fmtNum(series.lastWeekAverage!)} µg/m³.',
      ],
      confidence: (0.65 * leadTimeFactor(_daysAhead(peak))).clamp(0.3, 0.9),
      confidenceReason:
          'O modelo global de qualidade do ar tem resolução de '
          'dezenas de quilômetros; por isso a confiança parte de um nível '
          'moderado e cai com a distância da previsão.',
      limitations: const [
        'Estimativa de modelo atmosférico, não de estação de medição local.',
        'Não capta fontes pontuais, como uma avenida movimentada ou uma '
            'queimada próxima.',
      ],
      unreliableWhen: const [
        'Há queimadas ou incêndios na região, que o modelo demora a refletir.',
        'O bairro fica junto a vias de tráfego intenso.',
      ],
      optionsForReview: const [
        'Comparar com as estações de monitoramento oficiais (CETESB).',
        'Avaliar orientação a escolas sobre atividades ao ar livre.',
        'Avaliar reforço em unidades de saúde para casos respiratórios.',
      ],
      socialBenefit:
          'Avisar com antecedência permite que pessoas com '
          'doenças respiratórias se protejam e reduz idas ao pronto-socorro.',
    );
  }

  TerritoryAlert? _waste(Region region, TerritorySnapshot s, Thresholds t) {
    final series = s.indicator(IndicatorIds.waste);
    final capacity = series?.capacity;
    if (series == null || capacity == null || series.forecast.isEmpty) {
      return null;
    }
    final peak = _peak(series.forecast);
    final usage = peak.value / capacity * 100;
    if (usage < t.wastePercent) return null;

    return TerritoryAlert(
      id: _id(region, 'residuos'),
      regionId: region.id,
      indicatorId: series.id,
      title: 'Coleta de resíduos perto do limite da capacidade',
      plainSummary:
          'A quantidade de lixo coletada está crescendo e deve '
          'encostar no máximo que a coleta consegue atender. Pode sobrar lixo '
          'na rua.',
      severity: AlertSeverity.fromRatio(usage / t.wastePercent),
      evidence: [
        'Volume projetado: ${fmtNum(peak.value, decimals: 0)} t/dia em '
            '${fmtDate(peak.date)}.',
        'Capacidade de coleta: ${fmtNum(capacity, decimals: 0)} t/dia; uso '
            'previsto de ${fmtNum(usage, decimals: 0)}% '
            '(limiar: ${fmtNum(t.wastePercent, decimals: 0)}%).',
        if (series.weeklyTrendPercent != null)
          'Variação semanal: ${fmtSignedPercent(series.weeklyTrendPercent!)}.',
        _mapeText(series),
      ],
      confidence: trendConfidence(series.backtestMape),
      confidenceReason: _trendConfidenceReason(series),
      limitations: const [
        _syntheticLimitation,
        _linearLimitation,
        'A capacidade de coleta é um valor fixo ilustrativo; na prática ela '
            'varia com frota e equipes disponíveis.',
      ],
      unreliableWhen: const [
        'Houve mutirão de limpeza, feira ou evento que elevou o volume '
            'pontualmente.',
        'A coleta ficou suspensa em algum dia da janela analisada.',
      ],
      optionsForReview: const [
        'Avaliar reforço temporário de rotas de coleta.',
        'Avaliar ação de coleta seletiva e ecopontos na região.',
        'Confirmar a capacidade real disponível com a operadora.',
      ],
      socialBenefit:
          'Evitar o acúmulo de lixo reduz pontos de alagamento e '
          'focos de doenças como dengue e leptospirose.',
    );
  }

  TerritoryAlert? _services(Region region, TerritorySnapshot s, Thresholds t) {
    final series = s.indicator(IndicatorIds.services);
    final growth = series?.weeklyTrendPercent;
    if (series == null || growth == null) return null;
    if (growth < t.servicesGrowthPercent) return null;

    final values = series.historyValues;
    final lastWeek = Stats.mean(values.sublist(values.length - 7));
    final previousWeek = Stats.mean(
      values.sublist(values.length - 14, values.length - 7),
    );
    return TerritoryAlert(
      id: _id(region, 'servicos'),
      regionId: region.id,
      indicatorId: series.id,
      title: 'Demanda por serviços em alta',
      plainSummary:
          'O número de pedidos à prefeitura cresceu rápido na '
          'última semana. O atendimento pode demorar mais.',
      severity: AlertSeverity.fromRatio(
        1 + (growth - t.servicesGrowthPercent) / 100,
      ),
      evidence: [
        'Média da última semana: ${fmtNum(lastWeek, decimals: 0)} chamados/dia.',
        'Média da semana anterior: '
            '${fmtNum(previousWeek, decimals: 0)} chamados/dia.',
        'Crescimento: ${fmtSignedPercent(growth)} '
            '(limiar: ${fmtNum(t.servicesGrowthPercent, decimals: 0)}%).',
        _mapeText(series),
      ],
      confidence: trendConfidence(series.backtestMape),
      confidenceReason: _trendConfidenceReason(series),
      limitations: const [
        _syntheticLimitation,
        'Chamados medem quem consegue reclamar: bairros com menos acesso à '
            'internet aparecem menos, mesmo tendo mais problemas (viés de '
            'sub-registro).',
      ],
      unreliableWhen: const [
        'Houve campanha de divulgação do canal de atendimento, que aumenta os '
            'registros sem aumentar os problemas.',
        'Um único evento (ex.: temporal) concentrou os chamados.',
      ],
      optionsForReview: const [
        'Analisar quais categorias puxaram o crescimento.',
        'Avaliar reforço temporário das equipes de zeladoria.',
        'Cruzar com as ocorrências registradas pelos cidadãos no app.',
      ],
      socialBenefit:
          'Antecipar o aumento da demanda ajuda a manter o prazo '
          'de atendimento para os moradores da região.',
    );
  }
}

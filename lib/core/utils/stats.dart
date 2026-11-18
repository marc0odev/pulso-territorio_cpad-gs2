import 'dart:math';

/// Estatística básica usada nas projeções. Modelos simples e explicáveis
/// foram escolhidos de propósito: o gestor precisa entender a previsão.
class LinearFit {
  const LinearFit({
    required this.slope,
    required this.intercept,
    required this.r2,
  });

  final double slope;
  final double intercept;

  /// Coeficiente de determinação (0 a 1).
  final double r2;

  double predict(num x) => intercept + slope * x;
}

class Stats {
  const Stats._();

  static double mean(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  static double stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final m = mean(values);
    final sum = values.fold<double>(0, (acc, v) => acc + (v - m) * (v - m));
    return sqrt(sum / (values.length - 1));
  }

  /// Regressão linear por mínimos quadrados, com x = 0..n-1.
  static LinearFit fitLinear(List<double> y) {
    final n = y.length;
    if (n < 2) {
      return LinearFit(slope: 0, intercept: n == 1 ? y.first : 0, r2: 0);
    }
    final xMean = (n - 1) / 2;
    final yMean = mean(y);
    var sxy = 0.0, sxx = 0.0, syy = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (i - xMean) * (y[i] - yMean);
      sxx += (i - xMean) * (i - xMean);
      syy += (y[i] - yMean) * (y[i] - yMean);
    }
    final slope = sxy / sxx;
    final r2 = syy == 0 ? 0.0 : (sxy * sxy) / (sxx * syy);
    return LinearFit(slope: slope, intercept: yMean - slope * xMean, r2: r2);
  }

  /// Projeta [horizon] passos ajustando a tendência nos últimos [window] pontos.
  static List<double> forecastLinear(
    List<double> history, {
    int window = 14,
    int horizon = 7,
  }) {
    if (history.isEmpty) return const [];
    final start = max(0, history.length - window);
    final recent = history.sublist(start);
    final fit = fitLinear(recent);
    return [for (var h = 0; h < horizon; h++) fit.predict(recent.length + h)];
  }

  /// Backtest: esconde os últimos [horizon] pontos, projeta-os e devolve o erro
  /// percentual absoluto médio (MAPE, 0 a 1). `null` se não houver histórico.
  static double? backtestMape(
    List<double> history, {
    int window = 14,
    int horizon = 7,
  }) {
    if (history.length < window + horizon) return null;
    final train = history.sublist(0, history.length - horizon);
    final actual = history.sublist(history.length - horizon);
    final predicted = forecastLinear(train, window: window, horizon: horizon);
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i < horizon; i++) {
      if (actual[i] == 0) continue;
      sum += ((actual[i] - predicted[i]) / actual[i]).abs();
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  /// Quantos desvios-padrão [value] está distante da média de [baseline].
  static double zScore(double value, List<double> baseline) {
    final sd = stdDev(baseline);
    return sd == 0 ? 0 : (value - mean(baseline)) / sd;
  }
}

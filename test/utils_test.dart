import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_territorio/core/utils/anonymizer.dart';
import 'package:pulso_territorio/core/utils/stats.dart';
import 'package:pulso_territorio/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('lengthBetween explica o que falta', () {
      expect(
        Validators.lengthBetween('', min: 15, max: 300),
        Validators.requiredMessage,
      );
      expect(
        Validators.lengthBetween('curto', min: 15, max: 300),
        contains('faltam 10'),
      );
      expect(
        Validators.lengthBetween('a' * 301, min: 15, max: 300),
        contains('no máximo 300'),
      );
      expect(
        Validators.lengthBetween('Vazamento na calçada', min: 15, max: 300),
        isNull,
      );
    });

    test('numberInRange aceita vírgula e rejeita fora da faixa', () {
      expect(Validators.numberInRange('12,5', min: 1, max: 300), isNull);
      expect(Validators.numberInRange('150', min: 80, max: 400), isNull);
      expect(
        Validators.numberInRange('', min: 1, max: 300),
        'Informe um valor.',
      );
      expect(
        Validators.numberInRange('abc', min: 1, max: 300),
        contains('apenas números'),
      );
      expect(
        Validators.numberInRange('500', min: 80, max: 400, unit: 'L'),
        'O valor deve ficar entre 80 e 400 L.',
      );
    });

    test('parseNumber', () {
      expect(Validators.parseNumber(' 7,25 '), 7.25);
      expect(Validators.parseNumber('x'), isNull);
    });
  });

  group('Anonymizer', () {
    test('remove e-mail, CPF e telefone do texto', () {
      final redacted = Anonymizer.redact(
        'Falar com maria@exemplo.com, CPF 123.456.789-09, tel (11) 91234-5678.',
      );
      expect(redacted, isNot(contains('maria@exemplo.com')));
      expect(redacted, isNot(contains('123.456.789-09')));
      expect(redacted, isNot(contains('91234-5678')));
      expect(Anonymizer.placeholder.allMatches(redacted), hasLength(3));
    });

    test('preserva texto sem dados pessoais', () {
      const text = 'Vazamento na rua há 2 dias, perto do número 120.';
      expect(Anonymizer.redact(text), text);
      expect(Anonymizer.containsPersonalData(text), isFalse);
    });

    test('código anônimo tem 4 caracteres hexadecimais', () {
      expect(Anonymizer.randomCode(), matches(RegExp(r'^[0-9A-F]{4}$')));
    });
  });

  group('Stats', () {
    test('regressão linear recupera uma reta exata', () {
      final fit = Stats.fitLinear([10, 12, 14, 16, 18]);
      expect(fit.slope, closeTo(2, 1e-9));
      expect(fit.intercept, closeTo(10, 1e-9));
      expect(fit.r2, closeTo(1, 1e-9));
    });

    test('projeção continua a tendência', () {
      final forecast = Stats.forecastLinear([
        for (var i = 0; i < 14; i++) 100.0 + i,
      ], horizon: 3);
      expect(forecast[0], closeTo(114, 1e-9));
      expect(forecast[2], closeTo(116, 1e-9));
    });

    test('backtest de série perfeitamente linear tem erro zero', () {
      final mape = Stats.backtestMape([for (var i = 0; i < 30; i++) 50.0 + i]);
      expect(mape, closeTo(0, 1e-9));
    });

    test('backtest exige histórico suficiente', () {
      expect(Stats.backtestMape([1, 2, 3]), isNull);
    });

    test('z-score', () {
      expect(Stats.zScore(5, [5, 5, 5]), 0);
      expect(Stats.zScore(8, [4, 5, 6]), closeTo(3, 1e-9));
    });
  });
}

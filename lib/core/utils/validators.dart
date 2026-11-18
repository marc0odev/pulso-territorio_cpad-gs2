/// Validadores reutilizáveis para formulários. Retornam `null` quando o valor
/// é válido ou a mensagem de erro a ser exibida no campo.
library;

class Validators {
  const Validators._();

  static const requiredMessage = 'Preencha este campo.';

  static String? lengthBetween(
    String? value, {
    required int min,
    required int max,
    String field = 'Este campo',
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredMessage;
    if (text.length < min) {
      return '$field precisa de pelo menos $min caracteres '
          '(faltam ${min - text.length}).';
    }
    if (text.length > max) return '$field aceita no máximo $max caracteres.';
    return null;
  }

  static String? optionalMaxLength(String? value, {required int max}) {
    if ((value?.trim().length ?? 0) > max) {
      return 'Use no máximo $max caracteres.';
    }
    return null;
  }

  /// Aceita vírgula ou ponto como separador decimal.
  static double? parseNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    String unit = '',
  }) {
    if (value == null || value.trim().isEmpty) return 'Informe um valor.';
    final number = parseNumber(value);
    if (number == null) return 'Digite apenas números (ex.: 150 ou 12,5).';
    if (number < min || number > max) {
      final suffix = unit.isEmpty ? '' : ' $unit';
      return 'O valor deve ficar entre ${_trim(min)} e ${_trim(max)}$suffix.';
    }
    return null;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

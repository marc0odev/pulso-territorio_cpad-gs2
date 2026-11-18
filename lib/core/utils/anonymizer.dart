import 'dart:math';

/// Remove dados pessoais digitados por engano em textos livres e gera
/// identificadores anônimos. Nenhum dado pessoal é necessário para usar o app.
class Anonymizer {
  const Anonymizer._();

  static const placeholder = '[dado removido]';

  static final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final _cpf = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final _phone = RegExp(
    r'(\+55\s?)?\(?\b\d{2}\)?[\s-]?9?\d{4}[\s-]?\d{4}\b',
  );

  /// Substitui e-mails, CPFs e telefones por [placeholder].
  static String redact(String text) => text
      .replaceAll(_email, placeholder)
      .replaceAll(_cpf, placeholder)
      .replaceAll(_phone, placeholder)
      .trim();

  static bool containsPersonalData(String text) =>
      _email.hasMatch(text) || _cpf.hasMatch(text) || _phone.hasMatch(text);

  /// Código aleatório (não derivado de nenhum dado da pessoa), ex.: "A3F9".
  static String randomCode([Random? random]) {
    final rng = random ?? Random.secure();
    return rng.nextInt(0x10000).toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}

/// Formatação de números e datas no padrão brasileiro, sem dependências
/// externas (evita carregar tabelas de localidade só para poucos formatos).
library;

String fmtNum(num value, {int decimals = 1}) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

String fmtPercent(double fraction, {int decimals = 0}) =>
    '${fmtNum(fraction * 100, decimals: decimals)}%';

String fmtSignedPercent(double percent) {
  final sign = percent > 0 ? '+' : '';
  return '$sign${fmtNum(percent)}%';
}

String _two(int v) => v.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)}/${d.year} às ${_two(d.hour)}:${_two(d.minute)}';

/// 431000 -> "431 mil"; 2200000 -> "2,2 mi".
String fmtCompact(num value) {
  final abs = value.abs();
  if (abs >= 1e6) return '${fmtNum(value / 1e6)} mi';
  if (abs >= 1e3) return '${fmtNum(value / 1e3, decimals: 0)} mil';
  return fmtNum(value, decimals: 0);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

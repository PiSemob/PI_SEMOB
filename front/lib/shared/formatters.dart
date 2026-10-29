import 'package:intl/intl.dart';

final NumberFormat _inteiro = NumberFormat.decimalPattern('pt_BR');
final NumberFormat _moeda =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final DateFormat _data = DateFormat('dd/MM/yyyy');

String fmtInteiro(num valor) => _inteiro.format(valor.round());

String fmtMoeda(num valor) => _moeda.format(valor);

String fmtData(DateTime data) => _data.format(data);

final DateFormat _diaMes = DateFormat('dd/MM');

String fmtDiaMes(DateTime data) => _diaMes.format(data);

String fmtPercentual(num fracao, {int casas = 1}) =>
    '${(fracao * 100).toStringAsFixed(casas).replaceAll('.', ',')}%';

const List<String> diasSemana = <String>[
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom'
];

String fmtCompacto(num valor) {
  if (valor.abs() >= 1000000) return '${(valor / 1000000).toStringAsFixed(1)}M';
  if (valor.abs() >= 1000) return '${(valor / 1000).toStringAsFixed(0)}k';
  return valor.toStringAsFixed(0);
}

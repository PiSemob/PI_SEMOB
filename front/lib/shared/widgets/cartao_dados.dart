import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../formatters.dart';

@immutable
class IndicadorTela {
  const IndicadorTela(
      {required this.nome, required this.valor, this.unidade = ''});

  factory IndicadorTela.deJson(Map<String, dynamic> j) => IndicadorTela(
        nome: j['nome'] as String,
        valor: j['valor'],
        unidade: (j['unidade'] as String?) ?? '',
      );

  final String nome;
  final Object? valor;
  final String unidade;
}

@immutable
class TabelaTela {
  const TabelaTela({required this.colunas, required this.linhas});

  factory TabelaTela.deJson(Map<String, dynamic> j) => TabelaTela(
        colunas: <String>[
          for (final dynamic c in j['colunas'] as List<dynamic>) '$c'
        ],
        linhas: <List<Object?>>[
          for (final dynamic l in j['linhas'] as List<dynamic>)
            List<Object?>.from(l as List<dynamic>),
        ],
      );

  final List<String> colunas;
  final List<List<Object?>> linhas;
}

@immutable
class DadosTela {
  const DadosTela(
      {required this.titulo,
      this.indicadores = const <IndicadorTela>[],
      this.tabela});

  factory DadosTela.deJson(Map<String, dynamic> j) => DadosTela(
        titulo: (j['titulo'] as String?) ?? '',
        indicadores: <IndicadorTela>[
          for (final dynamic i
              in (j['indicadores'] as List<dynamic>?) ?? <dynamic>[])
            IndicadorTela.deJson(i as Map<String, dynamic>),
        ],
        tabela: j['tabela'] == null
            ? null
            : TabelaTela.deJson(j['tabela'] as Map<String, dynamic>),
      );

  final String titulo;
  final List<IndicadorTela> indicadores;
  final TabelaTela? tabela;
}

String formatarValor(Object? valor, String unidade) {
  if (valor == null) return '—';
  if (valor is num) {
    final String numero = valor == valor.roundToDouble() && valor.abs() >= 1
        ? fmtInteiro(valor)
        : NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2)
            .format(valor);
    if (unidade == 'R\$') return 'R\$ $numero';
    if (unidade == '%') return '$numero%';
    return unidade.isEmpty ? numero : '$numero $unidade';
  }
  return '$valor';
}

class CartaoDados extends StatelessWidget {
  const CartaoDados(
      {super.key, required this.dados, this.linhasVisiveis = 12, this.aviso});

  final DadosTela dados;

  final int linhasVisiveis;

  final String? aviso;

  @override
  Widget build(BuildContext context) {
    final TabelaTela? tabela = dados.tabela;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(dados.titulo, style: AppTextStyles.label),
          if (dados.indicadores.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final IndicadorTela i in dados.indicadores)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(i.nome, style: AppTextStyles.caption),
                        Text(formatarValor(i.valor, i.unidade),
                            style: AppTextStyles.label),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (tabela != null && tabela.linhas.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 36,
                columnSpacing: AppSpacing.md,
                headingTextStyle:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                columns: <DataColumn>[
                  for (final String c in tabela.colunas)
                    DataColumn(label: Text(c)),
                ],
                rows: <DataRow>[
                  for (final List<Object?> l
                      in tabela.linhas.take(linhasVisiveis))
                    DataRow(cells: <DataCell>[
                      for (final Object? v in l)
                        DataCell(Text(formatarValor(v, ''),
                            style: AppTextStyles.caption)),
                    ]),
                ],
              ),
            ),
            if (tabela.linhas.length > linhasVisiveis)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Mostrando $linhasVisiveis de ${tabela.linhas.length} linhas. '
                  '${aviso ?? 'Para a lista completa, exporte um relatório em Dados e relatórios.'}',
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

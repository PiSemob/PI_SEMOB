import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ColunaTabela<T> {
  const ColunaTabela({
    required this.titulo,
    required this.valor,
    this.texto,
    this.numerica = false,
  });

  final String titulo;

  final Comparable<dynamic> Function(T item) valor;

  final String Function(T item)? texto;
  final bool numerica;
}

class TabelaOrdenavel<T> extends StatefulWidget {
  const TabelaOrdenavel({
    super.key,
    required this.itens,
    required this.colunas,
    this.ordenarPor = 0,
    this.crescente = true,
  });

  final List<T> itens;
  final List<ColunaTabela<T>> colunas;
  final int ordenarPor;
  final bool crescente;

  @override
  State<TabelaOrdenavel<T>> createState() => _TabelaOrdenavelState<T>();
}

class _TabelaOrdenavelState<T> extends State<TabelaOrdenavel<T>> {
  late int _coluna = widget.ordenarPor;
  late bool _crescente = widget.crescente;

  @override
  Widget build(BuildContext context) {
    final ColunaTabela<T> criterio = widget.colunas[_coluna];
    final List<T> ordenados = <T>[...widget.itens]..sort((T a, T b) {
        final int r = criterio.valor(a).compareTo(criterio.valor(b));
        return _crescente ? r : -r;
      });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _coluna,
        sortAscending: _crescente,
        headingTextStyle:
            AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        columns: <DataColumn>[
          for (int i = 0; i < widget.colunas.length; i++)
            DataColumn(
              label: Text(widget.colunas[i].titulo),
              numeric: widget.colunas[i].numerica,
              onSort: (int coluna, bool crescente) => setState(() {
                _coluna = coluna;
                _crescente = crescente;
              }),
            ),
        ],
        rows: <DataRow>[
          for (final T item in ordenados)
            DataRow(
              cells: <DataCell>[
                for (final ColunaTabela<T> c in widget.colunas)
                  DataCell(Text(
                    c.texto?.call(item) ?? '${c.valor(item)}',
                    style: c.numerica
                        ? AppTextStyles.body
                            .copyWith(fontFamily: AppTextStyles.mono)
                        : AppTextStyles.body,
                  )),
              ],
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class MapaCalor extends StatelessWidget {
  const MapaCalor({
    super.key,
    required this.linhas,
    required this.colunas,
    required this.valores,
    required this.descrever,
    this.rotuloColuna,
  });

  final List<String> linhas;

  final List<String> colunas;

  final List<List<double>> valores;

  final String Function(int linha, int coluna, double valor) descrever;

  final bool Function(int coluna)? rotuloColuna;

  static const int _degraus = 5;

  static Color corDe(double fracao) {
    if (fracao <= 0) return AppColors.surfaceMuted;
    final int degrau = (fracao * _degraus).ceil().clamp(1, _degraus);
    return Color.lerp(AppColors.accentSoft, AppColors.primary,
        (degrau - 1) / (_degraus - 1))!;
  }

  @override
  Widget build(BuildContext context) {
    double maior = 0;
    for (final List<double> l in valores) {
      for (final double v in l) {
        if (v > maior) maior = v;
      }
    }
    const double larguraRotulo = 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double celula = (c.maxWidth - larguraRotulo) / colunas.length;
            return Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(width: larguraRotulo),
                    for (int j = 0; j < colunas.length; j++)
                      SizedBox(
                        width: celula,
                        child: (rotuloColuna?.call(j) ?? true)
                            ? Text(colunas[j],
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 10.5),
                                overflow: TextOverflow.visible,
                                softWrap: false)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                for (int i = 0; i < linhas.length; i++)
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: larguraRotulo,
                        child: Text(linhas[i], style: AppTextStyles.caption),
                      ),
                      for (int j = 0; j < colunas.length; j++)
                        Tooltip(
                          message: descrever(i, j, valores[i][j]),
                          child: Container(
                            width: celula - 1,
                            height: 23,
                            margin: const EdgeInsets.all(0.5),
                            color:
                                corDe(maior == 0 ? 0 : valores[i][j] / maior),
                          ),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md - 4),
        Row(
          children: <Widget>[
            const Text('Menos', style: AppTextStyles.caption),
            const SizedBox(width: 6),
            for (int d = 0; d <= _degraus; d++)
              Container(
                width: 16,
                height: 10,
                margin: const EdgeInsets.only(right: 2),
                color: corDe(d / _degraus),
              ),
            const SizedBox(width: 4),
            const Text('Mais', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

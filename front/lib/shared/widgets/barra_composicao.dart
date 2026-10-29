import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../formatters.dart';
import 'charts.dart';

class ParteComposicao {
  const ParteComposicao(
      {required this.nome, required this.valor, required this.cor});

  final String nome;
  final double valor;
  final Color cor;
}

class BarraComposicao extends StatelessWidget {
  const BarraComposicao({super.key, required this.partes});

  final List<ParteComposicao> partes;

  @override
  Widget build(BuildContext context) {
    final double total =
        partes.fold(0, (double a, ParteComposicao p) => a + p.valor);
    if (total <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            height: 16,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < partes.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex:
                        (partes[i].valor / total * 1000).round().clamp(1, 1000),
                    child: Tooltip(
                      message:
                          '${partes[i].nome}: ${fmtInteiro(partes[i].valor)}',
                      child: ColoredBox(
                          color: partes[i].cor, child: const SizedBox.expand()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md - 4),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final ParteComposicao p in partes)
              LegendaItem(
                cor: p.cor,
                texto: '${p.nome} ${fmtPercentual(p.valor / total)}',
                valor: fmtInteiro(p.valor),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/painel.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/faixa_indicadores.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class AbaReceita extends ConsumerWidget {
  const AbaReceita({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);

    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<DiaOperacao> dias = p
            .diasEntre(filtro.inicio, filtro.fim)
            .where((DiaOperacao d) => d.vendas != null)
            .toList();
        if (dias.isEmpty) {
          return const PaginaConteudo(
            barraSuperior: FiltroPeriodoBar(),
            children: <Widget>[
              AppCard(
                  child: EmptyState(
                      mensagem: 'Não há vendas de créditos neste período.')),
            ],
          );
        }
        final double total = somarDouble(dias.map((DiaOperacao d) => d.vendas));
        final List<DiaOperacao> comVenda =
            dias.where((DiaOperacao d) => d.vendas! > 0).toList();
        final DiaOperacao maior = dias.reduce(
            (DiaOperacao a, DiaOperacao b) => b.vendas! > a.vendas! ? b : a);
        final List<DiaOperacao> anteriores = p
            .diasAntes(filtro.inicio, filtro.fim)
            .where((DiaOperacao d) => d.vendas != null)
            .toList();
        final bool comparar = filtro.comparar && anteriores.isNotEmpty;

        final List<double> somaSemana = List<double>.filled(7, 0);
        final List<int> diasSemanaComVenda = List<int>.filled(7, 0);
        for (final DiaOperacao d in dias) {
          somaSemana[d.data.weekday - 1] += d.vendas!;
          diasSemanaComVenda[d.data.weekday - 1]++;
        }

        return PaginaConteudo(
          barraSuperior: const FiltroPeriodoBar(),
          children: <Widget>[
            FaixaIndicadores(
              itens: <Indicador>[
                Indicador(
                  titulo: 'Créditos vendidos',
                  valor: fmtMoeda(total),
                  detalhe: '${dias.length} dias com relatório',
                ),
                Indicador(
                  titulo: 'Média por dia com venda',
                  valor: comVenda.isEmpty
                      ? '—'
                      : fmtMoeda(total / comVenda.length),
                  detalhe: '${comVenda.length} dias com venda',
                ),
                Indicador(
                  titulo: 'Maior venda',
                  valor: fmtMoeda(maior.vendas!),
                  detalhe:
                      '${diasSemana[maior.data.weekday - 1]}, ${fmtData(maior.data)}',
                ),
              ],
            ),
            GraficoCard(
              titulo: 'Vendas de créditos por dia',
              subtitulo: comparar
                  ? '${filtro.descricao} · linha tracejada = período anterior'
                  : filtro.descricao,
              altura: 280,
              child: GraficoLinha(
                serie: <PontoSerie>[
                  for (final DiaOperacao d in dias)
                    PontoSerie(fmtDiaMes(d.data), d.vendas!),
                ],
                comparacao: comparar
                    ? <PontoSerie>[
                        for (final DiaOperacao d in anteriores)
                          PontoSerie(fmtDiaMes(d.data), d.vendas!),
                      ]
                    : null,
                curva: true,
                nomeSerie: 'Vendas',
                formatarValor: fmtMoeda,
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppSectionTitle(
                    'Vendas por dia da semana',
                    subtitulo: 'Média por dia, no período escolhido',
                  ),
                  GraficoBarrasHorizontais(
                    serie: <PontoSerie>[
                      for (int i = 0; i < 7; i++)
                        if (diasSemanaComVenda[i] > 0)
                          PontoSerie(diasSemana[i],
                              somaSemana[i] / diasSemanaComVenda[i]),
                    ],
                    formatarValor: fmtMoeda,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

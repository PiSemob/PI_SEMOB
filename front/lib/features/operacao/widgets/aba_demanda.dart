import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/painel.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/barra_composicao.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/faixa_indicadores.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';
import '../../../shared/widgets/tabela_ordenavel.dart';

class AbaDemanda extends ConsumerWidget {
  const AbaDemanda({super.key});

  static const Color corCatraca = AppColors.primary;
  static final Color corAntecipados = AppColors.chart[1];
  static final Color corNaoPagantes = AppColors.chart[3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);

    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<DiaOperacao> dias = p
            .diasEntre(filtro.inicio, filtro.fim)
            .where((DiaOperacao d) => d.passageiros != null)
            .toList();
        if (dias.isEmpty) {
          return PaginaConteudo(
            barraSuperior: const FiltroPeriodoBar(),
            children: <Widget>[
              AppCard(
                child: EmptyState(
                  icone: Icons.groups_outlined,
                  mensagem: 'Não há relatório de passageiros neste período.\n'
                      'Os dados de passageiros vão de ${fmtData(_primeiroComPassageiros(p))} '
                      'a ${fmtData(p.fim)}.',
                ),
              ),
            ],
          );
        }

        final int total = somar(dias.map((DiaOperacao d) => d.passageiros));
        final List<DiaOperacao> uteis =
            dias.where((DiaOperacao d) => d.data.weekday <= 5).toList();
        final DiaOperacao pico = dias.reduce((DiaOperacao a, DiaOperacao b) =>
            b.passageiros! > a.passageiros! ? b : a);

        return PaginaConteudo(
          barraSuperior: const FiltroPeriodoBar(),
          children: <Widget>[
            FaixaIndicadores(
              itens: <Indicador>[
                Indicador(
                  titulo: 'Total de passageiros',
                  valor: fmtInteiro(total),
                  detalhe: '${dias.length} dias com relatório',
                ),
                Indicador(
                  titulo: 'Média por dia útil',
                  valor: uteis.isEmpty
                      ? '—'
                      : fmtInteiro(
                          somar(uteis.map((DiaOperacao d) => d.passageiros)) /
                              uteis.length),
                  detalhe: 'segunda a sexta',
                ),
                Indicador(
                  titulo: 'Dia de maior demanda',
                  valor: fmtInteiro(pico.passageiros!),
                  detalhe:
                      '${diasSemana[pico.data.weekday - 1]}, ${fmtData(pico.data)}',
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppSectionTitle(
                    'Como os passageiros entraram',
                    subtitulo:
                        'Pagamento na catraca, créditos antecipados e não pagantes (gratuidades)',
                  ),
                  BarraComposicao(
                    partes: <ParteComposicao>[
                      ParteComposicao(
                        nome: 'Catraca',
                        valor: somar(dias.map((DiaOperacao d) => d.catraca))
                            .toDouble(),
                        cor: corCatraca,
                      ),
                      ParteComposicao(
                        nome: 'Antecipados',
                        valor: somar(dias.map((DiaOperacao d) => d.antecipados))
                            .toDouble(),
                        cor: corAntecipados,
                      ),
                      ParteComposicao(
                        nome: 'Não pagantes',
                        valor: somar(dias.map((DiaOperacao d) => d.naoPagantes))
                            .toDouble(),
                        cor: corNaoPagantes,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GraficoCard(
              titulo: 'Passageiros por dia',
              subtitulo: filtro.descricao,
              altura: 260,
              acao: Wrap(
                spacing: AppSpacing.md,
                children: <Widget>[
                  const LegendaItem(cor: corCatraca, texto: 'Pagantes'),
                  LegendaItem(cor: corNaoPagantes, texto: 'Não pagantes'),
                ],
              ),
              child: GraficoLinha(
                serie: <PontoSerie>[
                  for (final DiaOperacao d in dias)
                    PontoSerie(fmtDiaMes(d.data),
                        ((d.catraca ?? 0) + (d.antecipados ?? 0)).toDouble()),
                ],
                serieSecundaria: <PontoSerie>[
                  for (final DiaOperacao d in dias)
                    PontoSerie(
                        fmtDiaMes(d.data), (d.naoPagantes ?? 0).toDouble()),
                ],
                corSecundaria: corNaoPagantes,
                curva: true,
                nomeSerie: 'Pagantes',
                nomeSecundaria: 'Não pagantes',
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppSectionTitle(
                    'Passageiros dia a dia',
                    subtitulo: 'Toque no título de uma coluna para ordenar',
                  ),
                  TabelaOrdenavel<DiaOperacao>(
                    itens: dias,
                    crescente: false,
                    colunas: <ColunaTabela<DiaOperacao>>[
                      ColunaTabela<DiaOperacao>(
                        titulo: 'Data',
                        valor: (DiaOperacao d) => d.data,
                        texto: (DiaOperacao d) =>
                            '${fmtData(d.data)} · ${diasSemana[d.data.weekday - 1]}',
                      ),
                      ColunaTabela<DiaOperacao>(
                        titulo: 'Catraca',
                        numerica: true,
                        valor: (DiaOperacao d) => d.catraca ?? 0,
                        texto: (DiaOperacao d) => fmtInteiro(d.catraca ?? 0),
                      ),
                      ColunaTabela<DiaOperacao>(
                        titulo: 'Antecipados',
                        numerica: true,
                        valor: (DiaOperacao d) => d.antecipados ?? 0,
                        texto: (DiaOperacao d) =>
                            fmtInteiro(d.antecipados ?? 0),
                      ),
                      ColunaTabela<DiaOperacao>(
                        titulo: 'Não pagantes',
                        numerica: true,
                        valor: (DiaOperacao d) => d.naoPagantes ?? 0,
                        texto: (DiaOperacao d) =>
                            fmtInteiro(d.naoPagantes ?? 0),
                      ),
                      ColunaTabela<DiaOperacao>(
                        titulo: 'Total',
                        numerica: true,
                        valor: (DiaOperacao d) => d.passageiros ?? 0,
                        texto: (DiaOperacao d) =>
                            fmtInteiro(d.passageiros ?? 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static DateTime _primeiroComPassageiros(Painel p) => p.dias
      .firstWhere((DiaOperacao d) => d.passageiros != null,
          orElse: () => p.dias.first)
      .data;
}

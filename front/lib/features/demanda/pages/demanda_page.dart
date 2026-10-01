import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';
import '../widgets/filtros_demanda.dart';

class DemandaPage extends ConsumerWidget {
  const DemandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroDemanda filtro = ref.watch(filtroDemandaProvider);

    List<PontoSerie> pagantes = DadosExemplo.serieDiaria(21700);
    List<PontoSerie> gratuidades = DadosExemplo.serieDiaria(6900);
    if (filtro.ocultarFinaisDeSemana) {
      bool util(PontoSerie p) => p.valor > 15000;
      pagantes = pagantes.where(util).toList();
      gratuidades = gratuidades.take(pagantes.length).toList();
    }

    return PaginaConteudo(
      barraSuperior: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FiltroPeriodoBar(),
          FiltrosDemanda(),
        ],
      ),
      children: <Widget>[
        const GradeCards(
          colunasDesktop: 5,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Total de passageiros',
              valor: '944.1k',
              icone: Icons.groups_outlined,
              variacao: 4.2,
            ),
            AppMetricCard(
              titulo: 'Passageiros pagantes',
              valor: '651.5k',
              icone: Icons.credit_card_outlined,
              cor: AppColors.teal,
              detalhe: '69% do total',
              variacao: 3.8,
            ),
            AppMetricCard(
              titulo: 'Gratuidades',
              valor: '207.7k',
              icone: Icons.favorite_border,
              cor: AppColors.danger,
              detalhe: '22% do total',
              variacao: -1.2,
            ),
            AppMetricCard(
              titulo: 'Média diária',
              valor: '31.471',
              icone: Icons.query_stats_outlined,
              detalhe: 'passageiros/dia',
              variacao: 2.1,
            ),
            AppMetricCard(
              titulo: 'Pico de demanda',
              valor: '37.060',
              icone: Icons.trending_up,
              cor: AppColors.accent,
              detalhe: '08/09',
            ),
          ],
        ),
        GraficoCard(
          titulo: 'Curva de Demanda',
          subtitulo: 'Composição por tipo de passagem',
          altura: 300,
          acao: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LegendaItem(cor: AppColors.danger, texto: 'Gratuidades'),
              SizedBox(width: AppSpacing.md),
              LegendaItem(cor: AppColors.primary, texto: 'Pagantes'),
            ],
          ),
          child: GraficoLinha(
            serie: pagantes,
            serieSecundaria: gratuidades,
            corSecundaria: AppColors.danger,
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget mensal = GraficoCard(
              titulo: 'Tendência Mensal',
              subtitulo: '12 meses',
              child: GraficoLinha(
                serie: DadosExemplo.serieMensal(950000),
                cor: AppColors.accent,
              ),
            );
            final Widget porLinha = GraficoCard(
              titulo: 'Passageiros por Linha',
              subtitulo: 'Comparação do período',
              child: GraficoBarras(serie: DadosExemplo.passageirosPorLinha),
            );

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  mensal,
                  const SizedBox(height: AppSpacing.md),
                  porLinha,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: mensal),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: porLinha),
              ],
            );
          },
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle(
                'Demanda por Linha — Detalhamento',
                subtitulo: 'Passageiros estimados no período',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('LINHA')),
                    DataColumn(label: Text('ITINERÁRIO')),
                    DataColumn(label: Text('EMPRESA')),
                    DataColumn(label: Text('VIAGENS')),
                    DataColumn(label: Text('PASSAGEIROS')),
                  ],
                  rows: <DataRow>[
                    for (final LinhaOnibus l in DadosExemplo.linhas)
                      DataRow(
                        cells: <DataCell>[
                          DataCell(Text(l.codigo,
                              style: AppTextStyles.label)),
                          DataCell(Text(l.nome)),
                          DataCell(Text(l.empresa)),
                          DataCell(Text('${l.viagens}')),
                          DataCell(Text(fmtInteiro(l.viagens * 280))),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

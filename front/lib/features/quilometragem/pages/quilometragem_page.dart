import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class QuilometragemPage extends ConsumerWidget {
  const QuilometragemPage({super.key});

  Color _corAtingimento(int valor) {
    if (valor >= 110) return AppColors.accent;
    if (valor >= 95) return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(),
      children: <Widget>[
        const GradeCards(
          colunasDesktop: 5,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'KM diária total',
              valor: '5.833 km',
              icone: Icons.today_outlined,
              variacao: 2.3,
            ),
            AppMetricCard(
              titulo: 'KM mensal total',
              valor: '195.4k km',
              icone: Icons.calendar_month_outlined,
              cor: AppColors.teal,
              detalhe: 'Meta: 220.0k km',
              variacao: -1.8,
            ),
            AppMetricCard(
              titulo: 'Atingimento da meta',
              valor: '89%',
              icone: Icons.flag_outlined,
              cor: AppColors.warning,
              detalhe: 'quilometragem mensal',
            ),
            AppMetricCard(
              titulo: 'KM médio por veículo',
              valor: '122 km/dia',
              icone: Icons.directions_bus_outlined,
              cor: AppColors.accent,
              variacao: 1.1,
            ),
            AppMetricCard(
              titulo: 'Total de viagens',
              valor: '187',
              icone: Icons.route_outlined,
              cor: AppColors.purple,
              detalhe: 'viagens realizadas hoje',
            ),
          ],
        ),
        GraficoCard(
          titulo: 'Evolução da Quilometragem Mensal',
          subtitulo: 'Últimos 12 meses — total da frota',
          altura: 280,
          child: GraficoLinha(
            serie: DadosExemplo.serieMensal(200000),
            cor: AppColors.teal,
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget diaria = GraficoCard(
              titulo: 'KM Diária por Linha',
              subtitulo: 'Comparação entre linhas',
              child: GraficoBarras(serie: DadosExemplo.kmPorLinha),
            );
            final Widget meta = GraficoCard(
              titulo: 'KM Mensal vs Meta por Linha',
              subtitulo: 'Atingimento da meta',
              acao: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LegendaItem(cor: AppColors.primary, texto: 'KM Real'),
                  SizedBox(width: AppSpacing.md),
                  LegendaItem(cor: AppColors.border, texto: 'Meta'),
                ],
              ),
              child: GraficoBarras(
                serie: DadosExemplo.kmMesPorLinha,
                serieSecundaria: DadosExemplo.metaMesPorLinha,
                corSecundaria: AppColors.border,
              ),
            );

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  diaria,
                  const SizedBox(height: AppSpacing.md),
                  meta,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: diaria),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: meta),
              ],
            );
          },
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle('Quilometragem por Linha — Detalhamento'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('LINHA')),
                    DataColumn(label: Text('KM HOJE')),
                    DataColumn(label: Text('KM MÊS')),
                    DataColumn(label: Text('META MÊS')),
                    DataColumn(label: Text('ATINGIMENTO')),
                    DataColumn(label: Text('VIAGENS HOJE')),
                    DataColumn(label: Text('KM/VIAGEM')),
                  ],
                  rows: <DataRow>[
                    for (final LinhaOnibus l in DadosExemplo.linhas)
                      DataRow(
                        cells: <DataCell>[
                          DataCell(Text(l.codigo, style: AppTextStyles.label)),
                          DataCell(Text(fmtInteiro(l.kmHoje))),
                          DataCell(Text(fmtInteiro(l.kmMes))),
                          DataCell(Text(fmtInteiro(l.metaMes))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _corAtingimento(l.atingimento)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: Text(
                                '${l.atingimento}%',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _corAtingimento(l.atingimento),
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text('${l.viagens}')),
                          DataCell(Text('${l.kmPorViagem}')),
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

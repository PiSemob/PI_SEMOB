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

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);

    final List<PontoSerie> passageiros = DadosExemplo.serieDiaria(34800);
    final List<PontoSerie> anterior = <PontoSerie>[
      for (final PontoSerie p in passageiros) PontoSerie(p.rotulo, p.valor * 0.92),
    ];

    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(),
      children: <Widget>[
        GradeCards(
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Passageiros do dia',
              valor: fmtInteiro(34800),
              icone: Icons.people_outline,
              variacao: -1.1,
              variacaoLabel: 'vs ontem',
            ),
            const AppMetricCard(
              titulo: 'Passageiros da semana',
              valor: '216.8k',
              icone: Icons.calendar_view_week_outlined,
              variacao: 2.8,
            ),
            const AppMetricCard(
              titulo: 'Passageiros do mês',
              valor: '945.2k',
              icone: Icons.trending_up,
              variacao: 0,
            ),
            const AppMetricCard(
              titulo: 'Passageiros 15 dias',
              valor: '470.7k',
              icone: Icons.bar_chart,
              variacao: 1.4,
            ),
            AppMetricCard(
              titulo: 'Receita do dia',
              valor: fmtMoeda(78039),
              icone: Icons.attach_money,
              cor: AppColors.accent,
              variacao: -1.1,
              variacaoLabel: 'vs ontem',
            ),
            AppMetricCard(
              titulo: 'Receita do mês',
              valor: fmtMoeda(2119683),
              icone: Icons.work_outline,
              cor: AppColors.accent,
              variacao: 0,
            ),
            AppMetricCard(
              titulo: 'Total gratuidades',
              valor: fmtInteiro(207954),
              icone: Icons.favorite_border,
              cor: AppColors.danger,
              detalhe: '22% dos passageiros',
            ),
            AppMetricCard(
              titulo: 'Passageiros pagantes',
              valor: fmtInteiro(652210),
              icone: Icons.credit_card_outlined,
              cor: AppColors.teal,
              detalhe: '69% dos passageiros',
            ),
          ],
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget cardPassageiros = GraficoCard(
              titulo: 'Passageiros & Receita',
              subtitulo: filtro.comparar
                  ? 'Linha tracejada = período anterior'
                  : filtro.descricao,
              altura: 280,
              acao: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LegendaItem(cor: AppColors.accent, texto: 'Passageiros'),
                  SizedBox(width: AppSpacing.md),
                  LegendaItem(cor: AppColors.primary, texto: 'Receita'),
                ],
              ),
              child: GraficoLinha(
                serie: passageiros,
                comparacao: filtro.comparar ? anterior : null,
                cor: AppColors.accent,
              ),
            );
            final Widget evolucao = GraficoCard(
              titulo: 'Evolução Mensal',
              subtitulo: '12 meses · passageiros',
              altura: 280,
              child: GraficoBarras(serie: DadosExemplo.serieMensal(950000)),
            );

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  cardPassageiros,
                  const SizedBox(height: AppSpacing.md),
                  evolucao,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: cardPassageiros),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: evolucao),
              ],
            );
          },
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget linhas = GraficoCard(
              titulo: 'Desempenho por Linha',
              subtitulo: 'Passageiros e receita por linha hoje',
              child: GraficoBarras(
                serie: DadosExemplo.receitaPorLinha,
                cor: AppColors.accent,
              ),
            );
            const Widget frota = _StatusFrota();

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  linhas,
                  const SizedBox(height: AppSpacing.md),
                  frota,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: linhas),
                const SizedBox(width: AppSpacing.md),
                const Expanded(flex: 2, child: frota),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatusFrota extends StatelessWidget {
  const _StatusFrota();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionTitle(
            'Status da Frota',
            subtitulo: 'Situação dos veículos agora',
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _Situacao(
                  valor: '42',
                  rotulo: 'Em operação',
                  cor: AppColors.accent,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Situacao(
                  valor: '6',
                  rotulo: 'Em manutenção',
                  cor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Situacao extends StatelessWidget {
  const _Situacao({
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  final String valor;
  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            valor,
            style: AppTextStyles.metric.copyWith(color: cor),
          ),
          Text(rotulo, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

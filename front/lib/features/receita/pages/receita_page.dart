import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class ReceitaPage extends ConsumerWidget {
  const ReceitaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(),
      children: <Widget>[
        GradeCards(
          colunasDesktop: 5,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Receita de catraca',
              valor: fmtMoeda(2117232),
              icone: Icons.confirmation_number_outlined,
              variacao: 3.7,
            ),
            AppMetricCard(
              titulo: 'Receita antecipada',
              valor: fmtMoeda(169379),
              icone: Icons.credit_card_outlined,
              cor: AppColors.teal,
              detalhe: 'créditos pré-carregados',
              variacao: 5.2,
            ),
            AppMetricCard(
              titulo: 'Receita diária média',
              valor: fmtMoeda(70574),
              icone: Icons.today_outlined,
              cor: AppColors.accent,
              variacao: 2.1,
            ),
            AppMetricCard(
              titulo: 'Receita do mês',
              valor: fmtMoeda(2117232),
              icone: Icons.calendar_month_outlined,
              cor: AppColors.accent,
              variacao: 4.8,
            ),
            AppMetricCard(
              titulo: 'Ticket médio',
              valor: fmtMoeda(3.25),
              icone: Icons.sell_outlined,
              cor: AppColors.purple,
              detalhe: 'por passageiro pagante',
              variacao: 0.6,
            ),
          ],
        ),
        GraficoCard(
          titulo: 'Evolução da Receita',
          subtitulo: 'Composição por meio de pagamento',
          altura: 300,
          acao: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LegendaItem(cor: AppColors.primary, texto: 'Cartão'),
              SizedBox(width: AppSpacing.md),
              LegendaItem(cor: AppColors.accent, texto: 'Dinheiro'),
            ],
          ),
          child: GraficoLinha(
            serie: DadosExemplo.serieDiaria(52000),
            serieSecundaria: DadosExemplo.serieDiaria(18500),
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            const Widget empresa = _ReceitaPorEmpresa();
            const Widget pagamento = _MeiosPagamento();

            if (c.maxWidth < 1000) {
              return const Column(
                children: <Widget>[
                  empresa,
                  SizedBox(height: AppSpacing.md),
                  pagamento,
                ],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: empresa),
                SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: pagamento),
              ],
            );
          },
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget porLinha = GraficoCard(
              titulo: 'Receita por Linha',
              child: GraficoBarras(
                serie: DadosExemplo.receitaPorLinha,
                cor: AppColors.accent,
              ),
            );
            final Widget acumulada = GraficoCard(
              titulo: 'Receita Mensal Acumulada',
              subtitulo: 'Últimos 12 meses',
              child: GraficoLinha(serie: DadosExemplo.serieMensal(2100000)),
            );

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  porLinha,
                  const SizedBox(height: AppSpacing.md),
                  acumulada,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: porLinha),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: acumulada),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReceitaPorEmpresa extends StatelessWidget {
  const _ReceitaPorEmpresa();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle(
            'Receita por Empresa',
            subtitulo: 'Participação no período',
          ),
          SizedBox(
            height: 200,
            child: GraficoBarras(serie: DadosExemplo.receitaPorEmpresa),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final Empresa e in DadosExemplo.empresas)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(e.nome, style: AppTextStyles.body)),
                  Text(fmtMoeda(e.receita), style: AppTextStyles.label),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${e.participacao}%', style: AppTextStyles.caption),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MeiosPagamento extends StatelessWidget {
  const _MeiosPagamento();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle(
            'Meios de Pagamento',
            subtitulo: 'Distribuição',
          ),
          const SizedBox(
            height: 220,
            child: GraficoPizza(
              serie: <PontoSerie>[
                PontoSerie('Cartão', 74),
                PontoSerie('Dinheiro', 18),
                PontoSerie('Outros', 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

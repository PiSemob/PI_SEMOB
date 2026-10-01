import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class CreditosPage extends ConsumerWidget {
  const CreditosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(mostrarComparacao: false),
      children: <Widget>[
        GradeCards(
          colunasDesktop: 5,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Saldo em circulação',
              valor: fmtMoeda(169386),
              icone: Icons.account_balance_wallet_outlined,
              detalhe: 'créditos ativos não utilizados',
            ),
            AppMetricCard(
              titulo: 'Créditos vendidos',
              valor: fmtMoeda(2286618),
              icone: Icons.shopping_cart_outlined,
              cor: AppColors.accent,
              detalhe: 'total do período',
            ),
            AppMetricCard(
              titulo: 'Créditos utilizados',
              valor: fmtMoeda(2117232),
              icone: Icons.check_circle_outline,
              cor: AppColors.teal,
              detalhe: 'validações nas catracas',
            ),
            const AppMetricCard(
              titulo: 'Taxa de utilização',
              valor: '93%',
              icone: Icons.percent,
              cor: AppColors.purple,
              detalhe: 'utilizados / vendidos',
            ),
            AppMetricCard(
              titulo: 'Volume financeiro',
              valor: fmtMoeda(189712.32),
              icone: Icons.savings_outlined,
              cor: AppColors.warning,
              detalhe: 'estimativa total em circulação',
            ),
          ],
        ),
        GraficoCard(
          titulo: 'Venda x Utilização de Créditos',
          subtitulo: 'Evolução diária no período',
          altura: 300,
          acao: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LegendaItem(cor: AppColors.teal, texto: 'Utilizados'),
              SizedBox(width: AppSpacing.md),
              LegendaItem(cor: AppColors.accent, texto: 'Vendidos'),
            ],
          ),
          child: GraficoLinha(
            serie: DadosExemplo.serieDiaria(76200),
            serieSecundaria: DadosExemplo.serieDiaria(70600),
            cor: AppColors.accent,
            corSecundaria: AppColors.teal,
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget tendencia = GraficoCard(
              titulo: 'Tendência Mensal — Créditos',
              subtitulo: 'Saldo em circulação por mês',
              acao: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LegendaItem(cor: AppColors.accent, texto: 'Vendidos'),
                  SizedBox(width: AppSpacing.md),
                  LegendaItem(cor: AppColors.teal, texto: 'Utilizados'),
                ],
              ),
              child: GraficoBarras(
                serie: DadosExemplo.serieMensal(2286618),
                serieSecundaria: DadosExemplo.serieMensal(2117232),
                cor: AppColors.accent,
                corSecundaria: AppColors.teal,
              ),
            );
            const Widget anomalias = _Anomalias();

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  tendencia,
                  const SizedBox(height: AppSpacing.md),
                  anomalias,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: tendencia),
                const SizedBox(width: AppSpacing.md),
                const Expanded(flex: 2, child: anomalias),
              ],
            );
          },
        ),
        GraficoCard(
          titulo: 'Saldo Diário em Circulação',
          subtitulo: 'Diferença entre créditos vendidos e utilizados',
          child: GraficoBarras(
            serie: DadosExemplo.serieDiaria(5600, dias: 14),
            cor: AppColors.purple,
          ),
        ),
      ],
    );
  }
}

class _Anomalias extends StatelessWidget {
  const _Anomalias();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle(
            'Anomalias de Saldo',
            subtitulo: '1 detectada(s)',
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    size: 20, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Set/26', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Variação de saldo anormal detectada.',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        'Saldo: ${fmtMoeda(81360)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sistema monitora variações >20% no saldo mensal automaticamente '
            'via algoritmo de anomalia.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

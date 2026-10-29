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

class AbaCreditos extends ConsumerWidget {
  const AbaCreditos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);

    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<DiaOperacao> dias = p.diasEntre(filtro.inicio, filtro.fim);
        final List<DiaOperacao> movimento = dias
            .where((DiaOperacao d) => d.vendas != null && d.utilizacao != null)
            .toList();
        final List<DiaOperacao> comSaldo =
            dias.where((DiaOperacao d) => d.saldoCartoes != null).toList();
        final double vendas =
            somarDouble(movimento.map((DiaOperacao d) => d.vendas));
        final double utilizacao =
            somarDouble(movimento.map((DiaOperacao d) => d.utilizacao));

        return PaginaConteudo(
          barraSuperior: const FiltroPeriodoBar(mostrarComparacao: false),
          children: <Widget>[
            FaixaIndicadores(
              itens: <Indicador>[
                Indicador(
                  titulo: 'Saldo nos cartões',
                  valor: comSaldo.isEmpty
                      ? '—'
                      : fmtMoeda(comSaldo.last.saldoCartoes!),
                  detalhe: comSaldo.isEmpty
                      ? 'Sem relatório de saldo no período'
                      : 'em ${fmtData(comSaldo.last.data)}',
                ),
                Indicador(
                  titulo: 'Taxa de utilização',
                  valor: vendas == 0 ? '—' : fmtPercentual(utilizacao / vendas),
                  detalhe: 'créditos usados ÷ créditos vendidos',
                ),
                Indicador(
                  titulo: 'Diferença no período',
                  valor: fmtMoeda(vendas - utilizacao),
                  detalhe: vendas >= utilizacao
                      ? 'vendeu mais do que foi usado'
                      : 'usou mais do que foi vendido',
                ),
              ],
            ),
            GraficoCard(
              titulo: 'Venda × utilização',
              subtitulo: 'Créditos por dia, em R\$',
              altura: 280,
              acao: Wrap(
                spacing: AppSpacing.md,
                children: <Widget>[
                  const LegendaItem(cor: AppColors.primary, texto: 'Vendidos'),
                  LegendaItem(cor: AppColors.chart[1], texto: 'Utilizados'),
                ],
              ),
              child: GraficoLinha(
                serie: <PontoSerie>[
                  for (final DiaOperacao d in movimento)
                    PontoSerie(fmtDiaMes(d.data), d.vendas!),
                ],
                serieSecundaria: <PontoSerie>[
                  for (final DiaOperacao d in movimento)
                    PontoSerie(fmtDiaMes(d.data), d.utilizacao!),
                ],
                corSecundaria: AppColors.chart[1],
                curva: true,
                nomeSerie: 'Vendidos',
                nomeSecundaria: 'Utilizados',
                formatarValor: fmtMoeda,
              ),
            ),
            _SaldoNosCartoes(painel: p, dias: comSaldo),
          ],
        );
      },
    );
  }
}

class _SaldoNosCartoes extends StatefulWidget {
  const _SaldoNosCartoes({required this.painel, required this.dias});

  final Painel painel;
  final List<DiaOperacao> dias;

  @override
  State<_SaldoNosCartoes> createState() => _SaldoNosCartoesState();
}

class _SaldoNosCartoesState extends State<_SaldoNosCartoes> {
  bool _mensal = false;

  static const List<String> _meses = <String>[
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, DiaOperacao> fimDeMes = <String, DiaOperacao>{};
    for (final DiaOperacao d in widget.painel.dias
        .where((DiaOperacao d) => d.saldoCartoes != null)) {
      fimDeMes['${_meses[d.data.month - 1]}/${d.data.year % 100}'] = d;
    }

    return GraficoCard(
      titulo: 'Saldo em circulação',
      subtitulo: _mensal
          ? 'Último saldo de cada mês, em R\$'
          : 'Créditos guardados nos cartões no fim de cada dia, em R\$',
      altura: 260,
      filtros: Wrap(
        spacing: AppSpacing.xs,
        children: <Widget>[
          TagFiltro(
              texto: 'Diário',
              ativa: !_mensal,
              onTap: () => setState(() => _mensal = false)),
          TagFiltro(
              texto: 'Mensal',
              ativa: _mensal,
              onTap: () => setState(() => _mensal = true)),
        ],
      ),
      child: _mensal
          ? GraficoBarras(
              serie: <PontoSerie>[
                for (final MapEntry<String, DiaOperacao> e in fimDeMes.entries)
                  PontoSerie(e.key, e.value.saldoCartoes!),
              ],
              formatarValor: fmtMoeda,
              nomeSerie: 'Saldo',
            )
          : widget.dias.isEmpty
              ? const EmptyState(mensagem: 'Sem relatório de saldo no período.')
              : GraficoLinha(
                  serie: <PontoSerie>[
                    for (final DiaOperacao d in widget.dias)
                      PontoSerie(fmtDiaMes(d.data), d.saldoCartoes!),
                  ],
                  curva: true,
                  iniciarEmZero: false,
                  nomeSerie: 'Saldo',
                  formatarValor: fmtMoeda,
                ),
    );
  }
}

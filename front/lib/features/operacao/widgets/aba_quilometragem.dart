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
import '../../../shared/widgets/tabela_ordenavel.dart';
import 'seletor_linha.dart';

class AbaQuilometragem extends ConsumerWidget {
  const AbaQuilometragem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);
    final String? linha = ref.watch(linhaSelecionadaProvider);

    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<DiaOperacao> dias = p.diasEntre(filtro.inicio, filtro.fim);
        final List<LinhaNoDia> porLinhaDia =
            p.linhasEntre(filtro.inicio, filtro.fim);
        final List<_TotalLinha> totais = <_TotalLinha>[
          for (final LinhaOnibus l in p.linhas)
            _TotalLinha(
              l,
              somarDouble(porLinhaDia
                  .where((LinhaNoDia x) => x.linha == l.codigo)
                  .map((LinhaNoDia x) => x.km)),
              somar(porLinhaDia
                  .where((LinhaNoDia x) => x.linha == l.codigo)
                  .map((LinhaNoDia x) => x.viagens)),
            ),
        ];

        return PaginaConteudo(
          barraSuperior: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const FiltroPeriodoBar(),
              SeletorLinha(painel: p)
            ],
          ),
          children: <Widget>[
            FaixaIndicadores(itens: _resumo(dias, totais, linha)),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final Widget barras = AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppSectionTitle('Km por linha',
                          subtitulo: 'No período escolhido'),
                      GraficoBarrasHorizontais(
                        serie: <PontoSerie>[
                          for (final _TotalLinha t in totais)
                            if (t.km > 0) PontoSerie(t.linha.codigo, t.km),
                        ],
                        formatarValor: (num v) => '${fmtInteiro(v)} km',
                        descrever: (String codigo) =>
                            p.linha(codigo)?.destino ?? '',
                        destaque: linha,
                        onTap: (String codigo) => ref
                            .read(linhaSelecionadaProvider.notifier)
                            .selecionar(codigo == linha ? null : codigo),
                      ),
                    ],
                  ),
                );
                final Widget evolucao = _KmPorDia(
                    dias: dias, porLinhaDia: porLinhaDia, linha: linha);
                if (c.maxWidth < 1000) {
                  return Column(
                    children: <Widget>[
                      barras,
                      const SizedBox(height: AppSpacing.md),
                      evolucao
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 2, child: barras),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 3, child: evolucao),
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
                    'Quilometragem por linha',
                    subtitulo: 'Toque no título de uma coluna para ordenar',
                  ),
                  TabelaOrdenavel<_TotalLinha>(
                    itens: totais,
                    ordenarPor: 3,
                    crescente: false,
                    colunas: <ColunaTabela<_TotalLinha>>[
                      ColunaTabela<_TotalLinha>(
                        titulo: 'Linha',
                        valor: (_TotalLinha t) => t.linha.codigo,
                      ),
                      ColunaTabela<_TotalLinha>(
                        titulo: 'Trajeto',
                        valor: (_TotalLinha t) => t.linha.nome,
                      ),
                      ColunaTabela<_TotalLinha>(
                        titulo: 'Viagens',
                        numerica: true,
                        valor: (_TotalLinha t) => t.viagens,
                        texto: (_TotalLinha t) => fmtInteiro(t.viagens),
                      ),
                      ColunaTabela<_TotalLinha>(
                        titulo: 'Km',
                        numerica: true,
                        valor: (_TotalLinha t) => t.km,
                        texto: (_TotalLinha t) => fmtInteiro(t.km),
                      ),
                      ColunaTabela<_TotalLinha>(
                        titulo: 'Km por viagem',
                        numerica: true,
                        valor: (_TotalLinha t) => t.kmPorViagem,
                        texto: (_TotalLinha t) => t.kmPorViagem
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
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

  List<Indicador> _resumo(
      List<DiaOperacao> dias, List<_TotalLinha> totais, String? linha) {
    if (linha != null) {
      final _TotalLinha t =
          totais.firstWhere((_TotalLinha x) => x.linha.codigo == linha);
      return <Indicador>[
        Indicador(
            titulo: 'Km da linha $linha',
            valor: '${fmtInteiro(t.km)} km',
            detalhe: 'no período'),
        Indicador(
            titulo: 'Viagens',
            valor: fmtInteiro(t.viagens),
            detalhe: t.linha.nome),
        Indicador(
          titulo: 'Km por viagem',
          valor: t.kmPorViagem.toStringAsFixed(1).replaceAll('.', ','),
          detalhe: 'média da linha no período',
        ),
      ];
    }
    final double total = somarDouble(dias.map((DiaOperacao d) => d.kmTotal));
    final double improdutivo =
        somarDouble(dias.map((DiaOperacao d) => d.kmImprodutivo));
    final int viagens = somar(dias.map((DiaOperacao d) => d.viagensRealizadas));
    return <Indicador>[
      Indicador(
        titulo: 'Km rodados',
        valor: '${fmtInteiro(total)} km',
        detalhe: dias.isEmpty
            ? null
            : 'média de ${fmtInteiro(total / dias.length)} km por dia',
      ),
      Indicador(
        titulo: 'Km improdutivo',
        valor: total == 0 ? '—' : fmtPercentual(improdutivo / total),
        detalhe: '${fmtInteiro(improdutivo)} km sem passageiros',
      ),
      Indicador(
        titulo: 'Km por viagem',
        valor: viagens == 0
            ? '—'
            : ((total - improdutivo) / viagens)
                .toStringAsFixed(1)
                .replaceAll('.', ','),
        detalhe: 'km produtivo dividido pelas viagens',
      ),
    ];
  }
}

class _TotalLinha {
  _TotalLinha(this.linha, this.km, this.viagens);

  final LinhaOnibus linha;
  final double km;
  final int viagens;

  double get kmPorViagem => viagens == 0 ? 0 : km / viagens;
}

class _KmPorDia extends StatelessWidget {
  const _KmPorDia(
      {required this.dias, required this.porLinhaDia, required this.linha});

  final List<DiaOperacao> dias;
  final List<LinhaNoDia> porLinhaDia;
  final String? linha;

  @override
  Widget build(BuildContext context) {
    if (linha != null) {
      final List<LinhaNoDia> daLinha =
          porLinhaDia.where((LinhaNoDia l) => l.linha == linha).toList();
      return GraficoCard(
        titulo: 'Km por dia',
        subtitulo: 'Linha $linha',
        altura: 300,
        child: GraficoLinha(
          serie: <PontoSerie>[
            for (final LinhaNoDia l in daLinha)
              PontoSerie(fmtDiaMes(l.data), l.km)
          ],
          curva: true,
          nomeSerie: 'Km',
          formatarValor: (num v) => '${fmtInteiro(v)} km',
        ),
      );
    }
    final List<DiaOperacao> comKm =
        dias.where((DiaOperacao d) => d.kmTotal != null).toList();
    return GraficoCard(
      titulo: 'Km por dia',
      subtitulo: 'Todas as linhas',
      altura: 300,
      acao: Wrap(
        spacing: AppSpacing.md,
        children: <Widget>[
          const LegendaItem(cor: AppColors.primary, texto: 'Produtivo'),
          LegendaItem(cor: AppColors.chart[1], texto: 'Improdutivo'),
        ],
      ),
      child: GraficoLinha(
        serie: <PontoSerie>[
          for (final DiaOperacao d in comKm)
            PontoSerie(fmtDiaMes(d.data), d.kmProdutivo ?? 0),
        ],
        serieSecundaria: <PontoSerie>[
          for (final DiaOperacao d in comKm)
            PontoSerie(fmtDiaMes(d.data), d.kmImprodutivo ?? 0),
        ],
        corSecundaria: AppColors.chart[1],
        curva: true,
        nomeSerie: 'Produtivo',
        nomeSecundaria: 'Improdutivo',
        formatarValor: (num v) => '${fmtInteiro(v)} km',
      ),
    );
  }
}

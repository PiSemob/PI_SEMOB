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
import '../../../shared/widgets/mapa_calor.dart';
import '../../../shared/widgets/mapa_municipio.dart';
import '../../../shared/widgets/tabela_ordenavel.dart';
import 'seletor_linha.dart';

class AbaFrota extends ConsumerWidget {
  const AbaFrota({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);
    final String? linha = ref.watch(linhaSelecionadaProvider);

    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<DiaOperacao> dias = p.diasEntre(filtro.inicio, filtro.fim);
        final Map<String, int> viagens =
            p.viagensPorLinha(filtro.inicio, filtro.fim);
        final List<ViagemComProblema> problemas = p
            .problemasEntre(filtro.inicio, filtro.fim)
            .where((ViagemComProblema v) => linha == null || v.linha == linha)
            .toList();
        final LinhaOnibus? escolhida = linha == null ? null : p.linha(linha);

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
            FaixaIndicadores(
              itens: escolhida == null
                  ? _resumoDoSistema(dias, problemas.length)
                  : _resumoDaLinha(escolhida, viagens[escolhida.codigo] ?? 0,
                      problemas.length),
            ),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final Widget mapa = GraficoCard(
                  titulo: 'Fluxo de viagens',
                  subtitulo: escolhida == null
                      ? 'Todas as linhas no período · toque numa linha ao lado para destacar'
                      : 'Linha ${escolhida.codigo}: ${escolhida.origem} → ${escolhida.destino}',
                  altura: c.maxWidth < 600 ? 280 : 380,
                  child: MapaMunicipio(
                    rotularDestinos: true,
                    fluxos: fluxosDasLinhas(p, viagens, destaque: linha),
                  ),
                );
                final Widget porLinha = AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppSectionTitle('Viagens por linha',
                          subtitulo: 'No período escolhido'),
                      GraficoBarrasHorizontais(
                        serie: <PontoSerie>[
                          for (final MapEntry<String, int> e in viagens.entries)
                            PontoSerie(e.key, e.value.toDouble()),
                        ],
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
                if (c.maxWidth < 1000) {
                  return Column(
                    children: <Widget>[
                      mapa,
                      const SizedBox(height: AppSpacing.md),
                      porLinha
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: mapa),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: porLinha),
                  ],
                );
              },
            ),
            _CalorPorHorario(painel: p, linha: linha),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSectionTitle(
                    'Viagens com problema',
                    subtitulo: '${problemas.length} no período'
                        '${escolhida == null ? '' : ' · linha ${escolhida.codigo}'}',
                  ),
                  if (problemas.isEmpty)
                    const EmptyState(
                      icone: Icons.check_circle_outline,
                      mensagem:
                          'Nenhuma viagem deixou de ser iniciada, realizada ou terminada.',
                    )
                  else
                    TabelaOrdenavel<ViagemComProblema>(
                      itens: problemas,
                      crescente: false,
                      colunas: <ColunaTabela<ViagemComProblema>>[
                        ColunaTabela<ViagemComProblema>(
                          titulo: 'Data',
                          valor: (ViagemComProblema v) => v.data,
                          texto: (ViagemComProblema v) => fmtData(v.data),
                        ),
                        ColunaTabela<ViagemComProblema>(
                          titulo: 'Linha',
                          valor: (ViagemComProblema v) => v.linha,
                        ),
                        ColunaTabela<ViagemComProblema>(
                          titulo: 'Situação',
                          valor: (ViagemComProblema v) => v.situacaoTexto,
                        ),
                        ColunaTabela<ViagemComProblema>(
                          titulo: 'Atendimento',
                          valor: (ViagemComProblema v) => v.atendimento,
                        ),
                        ColunaTabela<ViagemComProblema>(
                          titulo: 'Saída programada',
                          valor: (ViagemComProblema v) =>
                              v.inicioProgramado ?? '',
                          texto: (ViagemComProblema v) =>
                              v.inicioProgramado ?? '—',
                        ),
                        ColunaTabela<ViagemComProblema>(
                          titulo: 'Veículo',
                          valor: (ViagemComProblema v) => v.prefixo ?? '',
                          texto: (ViagemComProblema v) => v.prefixo ?? '—',
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

  List<Indicador> _resumoDoSistema(List<DiaOperacao> dias, int problemas) {
    final List<DiaOperacao> comFrota =
        dias.where((DiaOperacao d) => d.veiculos != null).toList();
    final int programadas =
        somar(dias.map((DiaOperacao d) => d.viagensProgramadas));
    final int realizadas =
        somar(dias.map((DiaOperacao d) => d.viagensRealizadas));
    return <Indicador>[
      Indicador(
        titulo: 'Veículos por dia',
        valor: comFrota.isEmpty
            ? '—'
            : fmtInteiro(somar(comFrota.map((DiaOperacao d) => d.veiculos)) /
                comFrota.length),
        detalhe: comFrota.isEmpty
            ? null
            : 'máximo de ${comFrota.map((DiaOperacao d) => d.veiculos!).reduce((int a, int b) => a > b ? a : b)} num dia',
      ),
      Indicador(
        titulo: 'Cumprimento de viagens',
        valor: programadas == 0 ? '—' : fmtPercentual(realizadas / programadas),
        detalhe:
            '${fmtInteiro(realizadas)} de ${fmtInteiro(programadas)} programadas',
      ),
      Indicador(
        titulo: 'Viagens com problema',
        valor: fmtInteiro(problemas),
        detalhe: 'não iniciadas, não realizadas ou não terminadas',
      ),
    ];
  }

  List<Indicador> _resumoDaLinha(LinhaOnibus l, int viagens, int problemas) =>
      <Indicador>[
        Indicador(
          titulo: 'Viagens da linha ${l.codigo}',
          valor: fmtInteiro(viagens),
          detalhe: 'no período escolhido',
        ),
        Indicador(
          titulo: 'Veículos na linha',
          valor: fmtInteiro(l.veiculos),
          detalhe: l.duracaoMediaMin == null
              ? 'em toda a base'
              : 'em toda a base · viagem média de ${l.duracaoMediaMin!.round()} min',
        ),
        Indicador(
          titulo: 'Viagens com problema',
          valor: fmtInteiro(problemas),
          detalhe: 'na linha ${l.codigo}, no período',
        ),
      ];
}

class _CalorPorHorario extends StatelessWidget {
  const _CalorPorHorario({required this.painel, required this.linha});

  final Painel painel;
  final String? linha;

  @override
  Widget build(BuildContext context) {
    final List<ViagensFaixa> faixas = painel.faixas
        .where((ViagensFaixa f) => f.linha == (linha ?? ''))
        .toList();
    final List<int> horas = <int>{
      for (final ViagensFaixa f in painel.faixas) f.faixa
    }.toList()
      ..sort();
    final List<List<double>> valores = <List<double>>[
      for (int d = 0; d < 7; d++) <double>[for (final int _ in horas) 0],
    ];
    for (final ViagensFaixa f in faixas) {
      valores[f.diaSemana][horas.indexOf(f.faixa)] = f.viagens;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionTitle(
            'Partidas por faixa horária',
            subtitulo:
                'Média de viagens por dia, de ${fmtData(painel.inicio)} a ${fmtData(painel.fim)}'
                '${linha == null ? ' · todas as linhas' : ' · linha $linha'}',
          ),
          MapaCalor(
            linhas: diasSemana,
            colunas: <String>[for (final int h in horas) '${h}h'],
            valores: valores,
            rotuloColuna: (int j) => horas[j] % 3 == 0,
            descrever: (int d, int h, double v) =>
                '${diasSemana[d]}, ${horas[h]}h: ${v.toStringAsFixed(1).replaceAll('.', ',')} viagens',
          ),
        ],
      ),
    );
  }
}

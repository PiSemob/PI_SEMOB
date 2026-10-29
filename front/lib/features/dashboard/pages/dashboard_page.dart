import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../shared/widgets/mapa_municipio.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);

    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<DiaOperacao> dias = p.diasEntre(filtro.inicio, filtro.fim);
        final List<DiaOperacao> comPassageiros =
            dias.where((DiaOperacao d) => d.passageiros != null).toList();
        final int passageiros =
            somar(comPassageiros.map((DiaOperacao d) => d.passageiros));
        final int programadas =
            somar(dias.map((DiaOperacao d) => d.viagensProgramadas));
        final int realizadas =
            somar(dias.map((DiaOperacao d) => d.viagensRealizadas));
        final List<DiaOperacao> comFrota =
            dias.where((DiaOperacao d) => d.veiculos != null).toList();
        final double veiculosPorDia = comFrota.isEmpty
            ? 0
            : somar(comFrota.map((DiaOperacao d) => d.veiculos)) /
                comFrota.length;
        final List<DiaOperacao> comVendas =
            dias.where((DiaOperacao d) => d.vendas != null).toList();
        final double vendas =
            somarDouble(comVendas.map((DiaOperacao d) => d.vendas));

        return PaginaConteudo(
          barraSuperior: const FiltroPeriodoBar(),
          children: <Widget>[
            FaixaIndicadores(
              itens: <Indicador>[
                Indicador(
                  titulo: 'Passageiros',
                  valor: comPassageiros.isEmpty ? '—' : fmtInteiro(passageiros),
                  detalhe: comPassageiros.isEmpty
                      ? 'Sem relatório de passageiros no período'
                      : 'média de ${fmtInteiro(passageiros / comPassageiros.length)} por dia',
                  tendencia: <double>[
                    for (final DiaOperacao d in comPassageiros)
                      d.passageiros!.toDouble(),
                  ],
                  onTap: () => context.go('/operacao?aba=demanda'),
                ),
                Indicador(
                  titulo: 'Viagens realizadas',
                  valor: fmtInteiro(realizadas),
                  detalhe: programadas == 0
                      ? null
                      : '${fmtPercentual(realizadas / programadas)} das programadas',
                  tendencia: <double>[
                    for (final DiaOperacao d in dias)
                      if (d.viagensRealizadas != null)
                        d.viagensRealizadas!.toDouble(),
                  ],
                  onTap: () => context.go('/operacao?aba=frota'),
                ),
                Indicador(
                  titulo: 'Veículos em operação',
                  valor: fmtInteiro(veiculosPorDia),
                  detalhe:
                      'média por dia · ${p.veiculosDistintos} veículos na base',
                  tendencia: <double>[
                    for (final DiaOperacao d in comFrota) d.veiculos!.toDouble()
                  ],
                  onTap: () => context.go('/operacao?aba=frota'),
                ),
                Indicador(
                  titulo: 'Créditos vendidos',
                  valor: comVendas.isEmpty ? '—' : fmtMoeda(vendas),
                  detalhe: 'recargas nos cartões de transporte',
                  tendencia: <double>[
                    for (final DiaOperacao d in comVendas) d.vendas!
                  ],
                  onTap: () => context.go('/receita'),
                ),
              ],
            ),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final Widget mapa = GraficoCard(
                  titulo: 'Fluxo de viagens por linha',
                  subtitulo: 'Da Estação São Caetano ao bairro atendido · '
                      'arcos mais grossos, mais viagens no período',
                  altura: c.maxWidth < 600 ? 340 : 480,
                  child: MapaMunicipio(
                    rotularDestinos: true,
                    fluxos: fluxosDasLinhas(
                        p, p.viagensPorLinha(filtro.inicio, filtro.fim)),
                  ),
                );
                final Widget atencao =
                    _PrecisaDeAtencao(painel: p, filtro: filtro);
                if (c.maxWidth < 1000) {
                  return Column(
                    children: <Widget>[
                      mapa,
                      const SizedBox(height: AppSpacing.md),
                      atencao
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: mapa),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: atencao),
                  ],
                );
              },
            ),
            _PassageirosPorDia(painel: p, filtro: filtro, dias: comPassageiros),
          ],
        );
      },
    );
  }
}

class _PassageirosPorDia extends StatelessWidget {
  const _PassageirosPorDia(
      {required this.painel, required this.filtro, required this.dias});

  final Painel painel;
  final FiltroPeriodo filtro;
  final List<DiaOperacao> dias;

  @override
  Widget build(BuildContext context) {
    final List<DiaOperacao> anteriores = painel
        .diasAntes(filtro.inicio, filtro.fim)
        .where((DiaOperacao d) => d.passageiros != null)
        .toList();
    final bool comparar = filtro.comparar && anteriores.isNotEmpty;
    return GraficoCard(
      titulo: 'Passageiros por dia',
      subtitulo: comparar
          ? '${filtro.descricao} · linha tracejada = período anterior'
          : filtro.descricao,
      altura: 260,
      child: GraficoLinha(
        serie: <PontoSerie>[
          for (final DiaOperacao d in dias)
            PontoSerie(fmtDiaMes(d.data), d.passageiros!.toDouble()),
        ],
        comparacao: comparar
            ? <PontoSerie>[
                for (final DiaOperacao d in anteriores)
                  PontoSerie(fmtDiaMes(d.data), d.passageiros!.toDouble()),
              ]
            : null,
        curva: true,
        nomeSerie: 'Passageiros',
      ),
    );
  }
}

class _PrecisaDeAtencao extends StatelessWidget {
  const _PrecisaDeAtencao({required this.painel, required this.filtro});

  final Painel painel;
  final FiltroPeriodo filtro;

  @override
  Widget build(BuildContext context) {
    final List<DiaOperacao> dias = painel.diasEntre(filtro.inicio, filtro.fim);
    final List<ViagemComProblema> problemas =
        painel.problemasEntre(filtro.inicio, filtro.fim);
    final int faltaram = somar(dias.map((DiaOperacao d) =>
        d.viagensProgramadas == null || d.viagensRealizadas == null
            ? null
            : d.viagensProgramadas! - d.viagensRealizadas!));
    DiaOperacao? pior;
    for (final DiaOperacao d in dias) {
      if (d.viagensProgramadas == null || d.viagensRealizadas == null) continue;
      final int dif = d.viagensProgramadas! - d.viagensRealizadas!;
      if (dif > 0 &&
          (pior == null ||
              dif > pior.viagensProgramadas! - pior.viagensRealizadas!)) {
        pior = d;
      }
    }
    final double kmTotal = somarDouble(dias.map((DiaOperacao d) => d.kmTotal));
    final double kmImprodutivo =
        somarDouble(dias.map((DiaOperacao d) => d.kmImprodutivo));
    final int diasComSaldoNegativo = dias
        .where((DiaOperacao d) =>
            d.creditoCirculante != null && d.creditoCirculante! < 0)
        .length;
    final int suspeitos =
        painel.bases.fold(0, (int a, BaseDados b) => a + b.suspeitos);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle('Precisa de atenção',
              subtitulo: 'No período escolhido'),
          _ItemAtencao(
            alerta: problemas.isNotEmpty,
            titulo: problemas.isEmpty
                ? 'Nenhuma viagem com problema'
                : '${problemas.length} viagens com problema',
            detalhe: 'Não iniciadas, não realizadas ou não terminadas',
            rota: '/operacao?aba=frota',
          ),
          _ItemAtencao(
            alerta: faltaram > 0,
            titulo: faltaram == 0
                ? 'Todas as viagens programadas foram feitas'
                : '${fmtInteiro(faltaram)} viagens programadas não aconteceram',
            detalhe: pior == null
                ? 'Fator de cumprimento de viagem'
                : 'Pior dia: ${fmtData(pior.data)}, com '
                    '${pior.viagensProgramadas! - pior.viagensRealizadas!} a menos',
            rota: '/operacao?aba=frota',
          ),
          _ItemAtencao(
            alerta: kmTotal > 0 && kmImprodutivo / kmTotal > 0.05,
            titulo: kmTotal == 0
                ? 'Sem quilometragem no período'
                : 'Km improdutivo: ${fmtPercentual(kmImprodutivo / kmTotal)} do total',
            detalhe: '${fmtInteiro(kmImprodutivo)} km rodados sem passageiros',
            rota: '/operacao?aba=quilometragem',
          ),
          _ItemAtencao(
            alerta: diasComSaldoNegativo > 0,
            titulo:
                '$diasComSaldoNegativo dias com mais créditos usados que vendidos',
            detalhe: 'Venda × utilização de créditos',
            rota: '/receita?aba=creditos',
          ),
          _ItemAtencao(
            alerta: suspeitos > 0,
            titulo:
                '${fmtInteiro(suspeitos)} registros sinalizados como suspeitos',
            detalhe: 'Em toda a base, aguardando conferência',
            rota: '/dados?aba=integracoes',
            ultimo: true,
          ),
        ],
      ),
    );
  }
}

class _ItemAtencao extends StatelessWidget {
  const _ItemAtencao({
    required this.alerta,
    required this.titulo,
    required this.detalhe,
    required this.rota,
    this.ultimo = false,
  });

  final bool alerta;
  final String titulo;
  final String detalhe;
  final String rota;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(rota),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: ultimo
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              alerta ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: alerta ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(titulo,
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(detalhe, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

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

    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(),
      children: <Widget>[
        GradeCards(
          colunasDesktop: 3,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Receita do dia',
              valor: fmtMoeda(DadosExemplo.receitaHoje),
              icone: Icons.attach_money,
              cor: AppColors.accent,
              variacao: -1.1,
              variacaoLabel: 'vs ontem',
            ),
            AppMetricCard(
              titulo: 'Passageiros pagantes',
              valor: fmtInteiro(DadosExemplo.pagantesHoje),
              icone: Icons.credit_card_outlined,
              cor: AppColors.teal,
              detalhe: '${_percentual(DadosExemplo.pagantesHoje)} dos passageiros de hoje',
            ),
            AppMetricCard(
              titulo: 'Gratuidades',
              valor: fmtInteiro(DadosExemplo.gratuidadesHoje),
              icone: Icons.favorite_border,
              cor: AppColors.danger,
              detalhe: '${_percentual(DadosExemplo.gratuidadesHoje)} dos passageiros de hoje',
            ),
          ],
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget desempenho = _GraficoDesempenho(filtro: filtro);
            const Widget pagamentos = GraficoCard(
              titulo: 'Formas de Pagamento',
              subtitulo: 'Passageiros de hoje por tipo de pagamento',
              altura: 280,
              child: GraficoPizza(serie: DadosExemplo.formasPagamento),
            );

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  desempenho,
                  const SizedBox(height: AppSpacing.md),
                  pagamentos,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: desempenho),
                const SizedBox(width: AppSpacing.md),
                const Expanded(flex: 2, child: pagamentos),
              ],
            );
          },
        ),
      ],
    );
  }
}

String _percentual(double valor) =>
    '${(valor / DadosExemplo.passageirosHoje * 100).round()}%';

enum _Indicador { passageiros, receita }

/// Gráfico de linha com filtros de indicador e de linha de ônibus.
class _GraficoDesempenho extends StatefulWidget {
  const _GraficoDesempenho({required this.filtro});

  final FiltroPeriodo filtro;

  @override
  State<_GraficoDesempenho> createState() => _GraficoDesempenhoState();
}

class _GraficoDesempenhoState extends State<_GraficoDesempenho> {
  _Indicador _indicador = _Indicador.passageiros;
  String? _linha;

  @override
  Widget build(BuildContext context) {
    final int dias = (widget.filtro.fim.difference(widget.filtro.inicio).inDays + 1)
        .clamp(7, 90);
    final bool receita = _indicador == _Indicador.receita;
    final List<PontoSerie> serie = receita
        ? DadosExemplo.receitaDiaria(linha: _linha, dias: dias)
        : DadosExemplo.passageirosDiarios(linha: _linha, dias: dias);
    final List<PontoSerie>? anterior = widget.filtro.comparar
        ? <PontoSerie>[
            for (final PontoSerie p in serie) PontoSerie(p.rotulo, p.valor * 0.92),
          ]
        : null;

    final String escopo = _linha == null
        ? 'Sistema'
        : '$_linha · ${DadosExemplo.linhas.firstWhere((LinhaOnibus l) => l.codigo == _linha).nome}';

    return GraficoCard(
      titulo: 'Desempenho',
      subtitulo: '$escopo · últimos $dias dias',
      altura: 280,
      acao: widget.filtro.comparar
          ? const LegendaItem(cor: AppColors.textMuted, texto: 'Período anterior')
          : null,
      filtros: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          TagFiltro(
            texto: 'Passageiros',
            ativa: !receita,
            onTap: () => setState(() => _indicador = _Indicador.passageiros),
          ),
          TagFiltro(
            texto: 'Receita (R\$)',
            ativa: receita,
            onTap: () => setState(() => _indicador = _Indicador.receita),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SeletorLinha(
            linha: _linha,
            onChanged: (String? l) => setState(() => _linha = l),
          ),
        ],
      ),
      child: GraficoLinha(
        serie: serie,
        comparacao: anterior,
        cor: receita ? AppColors.accent : AppColors.primary,
        curva: true,
        formatarEixo: receita ? (num v) => 'R\$ ${fmtCompacto(v)}' : fmtCompacto,
        formatarValor: receita ? fmtMoeda : fmtInteiro,
      ),
    );
  }
}

class _SeletorLinha extends StatelessWidget {
  const _SeletorLinha({required this.linha, required this.onChanged});

  final String? linha;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: linha,
          isDense: true,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.expand_more, size: 16),
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) => <Widget>[
            const Center(child: Text('Todas as linhas')),
            for (final LinhaOnibus l in DadosExemplo.linhas)
              Center(child: Text('Linha ${l.codigo}')),
          ],
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(child: Text('Todas as linhas')),
            for (final LinhaOnibus l in DadosExemplo.linhas)
              DropdownMenuItem<String?>(
                value: l.codigo,
                child: Text('${l.codigo} · ${l.nome}'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../dados_exemplo.dart';
import '../formatters.dart';
import 'app_widgets.dart';

class GraficoCard extends StatelessWidget {
  const GraficoCard({
    super.key,
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.altura = 260,
    this.acao,
    this.filtros,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final double altura;
  final Widget? acao;

  final Widget? filtros;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionTitle(titulo, subtitulo: subtitulo, acao: acao),
          if (filtros != null) ...<Widget>[
            filtros!,
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(height: altura, child: child),
        ],
      ),
    );
  }
}

Widget _rotuloEixoX(List<PontoSerie> serie, double value, TitleMeta meta) {
  if (value != value.roundToDouble()) return const SizedBox.shrink();
  final int i = value.round();
  if (i < 0 || i >= serie.length) return const SizedBox.shrink();
  final int passo = serie.length <= 8 ? 1 : (serie.length / 6).ceil();
  if (i % passo != 0) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(serie[i].rotulo, style: AppTextStyles.caption),
  );
}

Widget _rotuloEixoY(double value, TitleMeta meta) {
  if (value == meta.max) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(fmtCompacto(value), style: AppTextStyles.caption),
  );
}

FlTitlesData _titulos(List<PontoSerie> serie) => FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (double v, TitleMeta m) => _rotuloEixoX(serie, v, m),
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 52,
          getTitlesWidget: _rotuloEixoY,
        ),
      ),
    );

double _passoRedondo(double bruto) {
  if (bruto <= 0) return 1;
  double potencia = 1;
  while (potencia * 10 <= bruto) {
    potencia *= 10;
  }
  for (final int m in <int>[1, 2, 5, 10]) {
    if (potencia * m >= bruto) return potencia * m;
  }
  return potencia * 10;
}

TextStyle get _estiloTooltip =>
    AppTextStyles.caption.copyWith(color: Colors.white);

String _itemTooltip(String? nome, String valor) =>
    nome == null ? valor : '$nome: $valor';

FlGridData get _grade => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (double _) => const FlLine(
          color: AppColors.border, strokeWidth: 1, dashArray: <int>[2, 4]),
    );

class GraficoLinha extends StatelessWidget {
  const GraficoLinha({
    super.key,
    required this.serie,
    this.comparacao,
    this.serieSecundaria,
    this.corSecundaria = AppColors.accent,
    this.curva = false,
    this.iniciarEmZero = true,
    this.formatarValor = fmtInteiro,
    this.nomeSerie,
    this.nomeSecundaria,
  });

  final List<PontoSerie> serie;

  final List<PontoSerie>? comparacao;

  final List<PontoSerie>? serieSecundaria;
  final Color corSecundaria;
  final bool curva;
  final bool iniciarEmZero;
  final String Function(num) formatarValor;

  final String? nomeSerie;
  final String? nomeSecundaria;

  bool get _temSecundaria =>
      serieSecundaria != null && serieSecundaria!.isNotEmpty;
  bool get _temComparacao => comparacao != null && comparacao!.isNotEmpty;

  List<String?> get _nomes => <String?>[
        nomeSerie,
        if (_temSecundaria) nomeSecundaria,
        if (_temComparacao) nomeSerie == null ? null : 'Período anterior',
      ];

  LineChartBarData _barra(List<PontoSerie> dados, Color cor, bool tracejada) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < dados.length; i++)
          FlSpot(i.toDouble(), dados[i].valor),
      ],
      isCurved: curva,
      curveSmoothness: 0.25,
      preventCurveOverShooting: true,
      color: cor,
      barWidth: curva ? 2.2 : 1.6,
      dashArray: tracejada ? <int>[6, 4] : null,
      dotData: FlDotData(
        show: curva && !tracejada && dados.length <= 12,
        getDotPainter: (FlSpot _, double __, LineChartBarData ___, int ____) =>
            FlDotCirclePainter(
          radius: 3,
          color: AppColors.surface,
          strokeColor: cor,
          strokeWidth: 2,
        ),
      ),
      belowBarData: BarAreaData(
        show: !tracejada,
        color: curva ? null : cor.withValues(alpha: 0.06),
        gradient: curva
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  cor.withValues(alpha: 0.18),
                  cor.withValues(alpha: 0)
                ],
              )
            : null,
      ),
    );
  }

  LineTouchData get _toque => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot _) => AppColors.ink,
          tooltipRoundedRadius: AppSpacing.radiusSm,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> pontos) => <LineTooltipItem>[
            for (final LineBarSpot p in pontos)
              LineTooltipItem(
                <String>[
                  if (p == pontos.first && p.x.round() < serie.length)
                    serie[p.x.round()].rotulo,
                  _itemTooltip(_nomes[p.barIndex], formatarValor(p.y)),
                ].join('\n'),
                _estiloTooltip,
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(
          mensagem: 'Sem dados para o período selecionado.');
    }
    double? minY = 0;
    double? maxY;
    if (!iniciarEmZero) {
      final Iterable<double> valores = <PontoSerie>[
        ...serie,
        ...?serieSecundaria,
        ...?comparacao
      ].map((PontoSerie p) => p.valor);
      final double menor =
          valores.reduce((double a, double b) => a < b ? a : b);
      final double maior =
          valores.reduce((double a, double b) => a > b ? a : b);
      final double folga = (maior - menor) == 0 ? maior * 0.1 : (maior - menor);
      final double passo = _passoRedondo(folga / 4);
      minY = ((menor - folga * 0.3) / passo).floorToDouble() * passo;
      if (minY < 0) minY = 0;
      maxY = ((maior + folga * 0.15) / passo).ceilToDouble() * passo;
    }
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: _grade,
        borderData: FlBorderData(show: false),
        titlesData: _titulos(serie),
        lineTouchData: _toque,
        lineBarsData: <LineChartBarData>[
          _barra(serie, AppColors.primary, false),
          if (_temSecundaria) _barra(serieSecundaria!, corSecundaria, false),
          if (_temComparacao) _barra(comparacao!, AppColors.textMuted, true),
        ],
      ),
    );
  }
}

class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.serie,
    this.formatarValor = fmtInteiro,
    this.nomeSerie,
  });

  final List<PontoSerie> serie;
  final String Function(num) formatarValor;
  final String? nomeSerie;

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(
          mensagem: 'Sem dados para o período selecionado.');
    }
    return BarChart(
      BarChartData(
        gridData: _grade,
        borderData: FlBorderData(show: false),
        titlesData: _titulos(serie),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData _) => AppColors.ink,
            tooltipRoundedRadius: AppSpacing.radiusSm,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (BarChartGroupData grupo, int i,
                    BarChartRodData barra, int indiceBarra) =>
                BarTooltipItem(
              '${serie[i].rotulo}\n${_itemTooltip(nomeSerie, formatarValor(barra.toY))}',
              _estiloTooltip,
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < serie.length; i++)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: serie[i].valor,
                  color: AppColors.primary,
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class LegendaItem extends StatelessWidget {
  const LegendaItem({
    super.key,
    required this.cor,
    required this.texto,
    this.valor,
  });

  final Color cor;
  final String texto;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 8,
          width: 8,
          color: cor,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            valor == null ? texto : '$texto  ·  $valor',
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class GraficoBarrasHorizontais extends StatelessWidget {
  const GraficoBarrasHorizontais({
    super.key,
    required this.serie,
    this.formatarValor = fmtInteiro,
    this.descrever,
    this.destaque,
    this.onTap,
  });

  final List<PontoSerie> serie;
  final String Function(num) formatarValor;

  final String Function(String rotulo)? descrever;

  final String? destaque;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(
          mensagem: 'Sem dados para o período selecionado.');
    }
    final List<PontoSerie> ordenada = <PontoSerie>[...serie]
      ..sort((PontoSerie a, PontoSerie b) => b.valor.compareTo(a.valor));
    final double maior = ordenada.first.valor <= 0 ? 1 : ordenada.first.valor;

    return Column(
      children: <Widget>[
        for (final PontoSerie p in ordenada)
          InkWell(
            onTap: onTap == null ? null : () => onTap!(p.rotulo),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 190,
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: p.rotulo,
                            style: AppTextStyles.label
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (descrever != null)
                            TextSpan(
                                text: '  ${descrever!(p.rotulo)}',
                                style: AppTextStyles.caption),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (p.valor / maior).clamp(0.01, 1),
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: destaque == null || destaque == p.rotulo
                                ? AppColors.primary
                                : AppColors.chart[3],
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(7)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 84,
                    child: Text(
                      formatarValor(p.valor),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.label
                          .copyWith(fontFamily: AppTextStyles.mono),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

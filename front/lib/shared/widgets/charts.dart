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
  // Com muitos pontos, mostra só um rótulo a cada `passo`, para não sobrepor.
  final int passo = (serie.length / 6).ceil();
  if (i % passo != 0) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(serie[i].rotulo, style: AppTextStyles.caption),
  );
}

Widget _rotuloEixoY(
  double value,
  TitleMeta meta, [
  String Function(num) formatar = fmtCompacto,
]) {
  if (value == meta.max) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(formatar(value), style: AppTextStyles.caption),
  );
}

FlTitlesData _titulos(
  List<PontoSerie> serie, {
  String Function(num) formatarEixo = fmtCompacto,
}) =>
    FlTitlesData(
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
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 52,
          getTitlesWidget: (double v, TitleMeta m) => _rotuloEixoY(v, m, formatarEixo),
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

FlGridData get _grade => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (double _) =>
          const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: <int>[2, 4]),
    );

class GraficoLinha extends StatelessWidget {
  const GraficoLinha({
    super.key,
    required this.serie,
    this.comparacao,
    this.serieSecundaria,
    this.cor = AppColors.primary,
    this.corSecundaria = AppColors.accent,
    this.curva = false,
    this.iniciarEmZero = true,
    this.formatarEixo = fmtCompacto,
    this.formatarValor = fmtInteiro,
  });

  final List<PontoSerie> serie;

  final List<PontoSerie>? comparacao;

  final List<PontoSerie>? serieSecundaria;
  final Color cor;
  final Color corSecundaria;
  final bool curva;
  final bool iniciarEmZero;
  final String Function(num) formatarEixo;
  final String Function(num) formatarValor;

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
                colors: <Color>[cor.withValues(alpha: 0.18), cor.withValues(alpha: 0)],
              )
            : null,
      ),
    );
  }

  LineTouchData get _toque => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot _) => AppColors.ink,
          tooltipRoundedRadius: AppSpacing.radius,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> pontos) => <LineTooltipItem>[
            for (final LineBarSpot p in pontos)
              LineTooltipItem(
                p == pontos.first && p.x.round() < serie.length
                    ? '${serie[p.x.round()].rotulo}\n${formatarValor(p.y)}'
                    : formatarValor(p.y),
                AppTextStyles.caption.copyWith(color: Colors.white),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(mensagem: 'Sem dados para o período selecionado.');
    }
    double? minY = 0;
    double? maxY;
    if (!iniciarEmZero) {
      final Iterable<double> valores = <PontoSerie>[...serie, ...?serieSecundaria, ...?comparacao]
          .map((PontoSerie p) => p.valor);
      final double menor = valores.reduce((double a, double b) => a < b ? a : b);
      final double maior = valores.reduce((double a, double b) => a > b ? a : b);
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
        titlesData: _titulos(serie, formatarEixo: formatarEixo),
        lineTouchData: _toque,
        lineBarsData: <LineChartBarData>[
          _barra(serie, cor, false),
          if (serieSecundaria != null && serieSecundaria!.isNotEmpty)
            _barra(serieSecundaria!, corSecundaria, false),
          if (comparacao != null && comparacao!.isNotEmpty)
            _barra(comparacao!, AppColors.textMuted, true),
        ],
      ),
    );
  }
}

class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.serie,
    this.cor = AppColors.primary,
    this.serieSecundaria,
    this.corSecundaria = AppColors.secondary,
  });

  final List<PontoSerie> serie;
  final Color cor;

  final List<PontoSerie>? serieSecundaria;
  final Color corSecundaria;

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(mensagem: 'Sem dados para o período selecionado.');
    }
    return BarChart(
      BarChartData(
        gridData: _grade,
        borderData: FlBorderData(show: false),
        titlesData: _titulos(serie),
        barTouchData: BarTouchData(enabled: true),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < serie.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: serie[i].valor,
                  color: cor,
                  width: serieSecundaria == null ? 14 : 8,
                  borderRadius: BorderRadius.zero,
                ),
                if (serieSecundaria != null && i < serieSecundaria!.length)
                  BarChartRodData(
                    toY: serieSecundaria![i].valor,
                    color: corSecundaria,
                    width: 8,
                    borderRadius: BorderRadius.zero,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class GraficoPizza extends StatelessWidget {
  const GraficoPizza({super.key, required this.serie});

  final List<PontoSerie> serie;

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(mensagem: 'Sem dados para o período selecionado.');
    }
    final double total = serie.fold(0, (double a, PontoSerie p) => a + p.valor);

    return Row(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double raio = ((c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) / 2 - 4)
                  .clamp(40, 94);
              return PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: raio * 0.45,
                  sections: <PieChartSectionData>[
                    for (int i = 0; i < serie.length; i++)
                      PieChartSectionData(
                        value: serie[i].valor,
                        color: AppColors.chart[i % AppColors.chart.length],
                        radius: raio * 0.55,
                        title: total == 0
                            ? ''
                            : '${(serie[i].valor / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < serie.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LegendaItem(
                    cor: AppColors.chart[i % AppColors.chart.length],
                    texto: serie[i].rotulo,
                    valor: fmtCompacto(serie[i].valor),
                  ),
                ),
            ],
          ),
        ),
      ],
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

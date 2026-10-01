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
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final double altura;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionTitle(titulo, subtitulo: subtitulo, acao: acao),
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
          interval: (serie.length / 8).ceilToDouble(),
          getTitlesWidget: (double v, TitleMeta m) => _rotuloEixoX(serie, v, m),
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: _rotuloEixoY,
        ),
      ),
    );

FlGridData get _grade => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (double _) =>
          const FlLine(color: AppColors.border, strokeWidth: 1),
    );

class GraficoLinha extends StatelessWidget {
  const GraficoLinha({
    super.key,
    required this.serie,
    this.comparacao,
    this.serieSecundaria,
    this.cor = AppColors.primary,
    this.corSecundaria = AppColors.accent,
  });

  final List<PontoSerie> serie;

  final List<PontoSerie>? comparacao;

  final List<PontoSerie>? serieSecundaria;
  final Color cor;
  final Color corSecundaria;

  LineChartBarData _barra(List<PontoSerie> dados, Color cor, bool tracejada) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < dados.length; i++)
          FlSpot(i.toDouble(), dados[i].valor),
      ],
      isCurved: true,
      curveSmoothness: 0.25,
      color: cor,
      barWidth: 2.5,
      dashArray: tracejada ? <int>[6, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: !tracejada,
        color: cor.withValues(alpha: 0.10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const EmptyState(mensagem: 'Sem dados para o período selecionado.');
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: _grade,
        borderData: FlBorderData(show: false),
        titlesData: _titulos(serie),
        lineTouchData: const LineTouchData(handleBuiltInTouches: true),
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
                  width: serieSecundaria == null ? 18 : 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                if (serieSecundaria != null && i < serieSecundaria!.length)
                  BarChartRodData(
                    toY: serieSecundaria![i].valor,
                    color: corSecundaria,
                    width: 10,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
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
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: <PieChartSectionData>[
                for (int i = 0; i < serie.length; i++)
                  PieChartSectionData(
                    value: serie[i].valor,
                    color: AppColors.chart[i % AppColors.chart.length],
                    radius: 52,
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
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
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

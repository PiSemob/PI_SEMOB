import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_widgets.dart';

class Indicador {
  const Indicador({
    required this.titulo,
    required this.valor,
    this.detalhe,
    this.tendencia,
    this.onTap,
  });

  final String titulo;
  final String valor;
  final String? detalhe;

  final List<double>? tendencia;

  final VoidCallback? onTap;
}

class FaixaIndicadores extends StatelessWidget {
  const FaixaIndicadores({super.key, required this.itens});

  final List<Indicador> itens;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final int porLinha = c.maxWidth >= 860
              ? itens.length
              : c.maxWidth >= 480
                  ? 2
                  : 1;
          final List<Widget> linhas = <Widget>[];
          for (int i = 0; i < itens.length; i += porLinha) {
            final List<Indicador> grupo =
                itens.sublist(i, (i + porLinha).clamp(0, itens.length));
            if (i > 0) linhas.add(const Divider(height: 1));
            linhas.add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int j = 0; j < porLinha; j++) ...<Widget>[
                      if (j > 0) const VerticalDivider(width: 1),
                      Expanded(
                        child: j < grupo.length
                            ? _Celula(indicador: grupo[j])
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return Column(mainAxisSize: MainAxisSize.min, children: linhas);
        },
      ),
    );
  }
}

class _Celula extends StatelessWidget {
  const _Celula({required this.indicador});

  final Indicador indicador;

  @override
  Widget build(BuildContext context) {
    final Indicador i = indicador;
    final Widget conteudo = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i.titulo,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              if (i.onTap != null)
                const Icon(Icons.arrow_forward,
                    size: 15, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(i.valor, style: AppTextStyles.metric),
          if (i.detalhe != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(i.detalhe!, style: AppTextStyles.caption),
          ],
          if (i.tendencia != null && i.tendencia!.length > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.sm + 2),
            SizedBox(
              height: 30,
              width: double.infinity,
              child: CustomPaint(painter: _TendenciaPainter(i.tendencia!)),
            ),
          ],
        ],
      ),
    );
    if (i.onTap == null) return conteudo;
    return InkWell(
        onTap: i.onTap, hoverColor: AppColors.surfaceMuted, child: conteudo);
  }
}

class _TendenciaPainter extends CustomPainter {
  _TendenciaPainter(this.valores);

  final List<double> valores;

  @override
  void paint(Canvas canvas, Size size) {
    final double maior = valores.reduce((double a, double b) => a > b ? a : b);
    final double menor = valores.reduce((double a, double b) => a < b ? a : b);
    final double faixa = (maior - menor) == 0 ? 1 : maior - menor;
    Offset ponto(int i) => Offset(
          i * size.width / (valores.length - 1),
          size.height - 2 - (valores[i] - menor) / faixa * (size.height - 4),
        );
    final Path linha = Path()..moveTo(ponto(0).dx, ponto(0).dy);
    for (int i = 1; i < valores.length; i++) {
      linha.lineTo(ponto(i).dx, ponto(i).dy);
    }
    final Path area = Path.from(linha)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = AppColors.primarySoft);
    canvas.drawPath(
      linha,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_TendenciaPainter antigo) => antigo.valores != valores;
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class Responsivo {
  const Responsivo._();

  static bool mobile(BuildContext c) => MediaQuery.sizeOf(c).width < 700;
  static bool tablet(BuildContext c) {
    final double w = MediaQuery.sizeOf(c).width;
    return w >= 700 && w < 1100;
  }

  static bool desktop(BuildContext c) => MediaQuery.sizeOf(c).width >= 1100;

  static int colunas(BuildContext c) {
    if (desktop(c)) return 4;
    if (tablet(c)) return 2;
    return 1;
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.icone,
    this.variacao,
    this.variacaoLabel = 'vs período anterior',
    this.detalhe,
    this.cor,
  });

  final String titulo;
  final String valor;
  final IconData? icone;

  final double? variacao;
  final String variacaoLabel;

  final String? detalhe;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final Color destaque = cor ?? AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  style: AppTextStyles.overline,
                  maxLines: 2,
                ),
              ),
              if (icone != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: destaque.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icone, size: 16, color: destaque),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: AppTextStyles.metric),
          ),
          if (variacao != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _Variacao(valor: variacao!, label: variacaoLabel),
          ] else if (detalhe != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(detalhe!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

class _Variacao extends StatelessWidget {
  const _Variacao({required this.valor, required this.label});

  final double valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool positiva = valor >= 0;
    final Color cor = positiva ? AppColors.success : AppColors.danger;

    return Row(
      children: <Widget>[
        Icon(positiva ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13, color: cor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${valor.abs().toStringAsFixed(1)}%',
          style: AppTextStyles.caption
              .copyWith(color: cor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icone,
    this.secundario = false,
    this.carregando = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool secundario;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final Widget conteudo = carregando
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    if (secundario) {
      return OutlinedButton.icon(
        onPressed: carregando ? null : onPressed,
        icon: icone == null ? const SizedBox.shrink() : Icon(icone, size: 18),
        label: conteudo,
      );
    }
    return FilledButton.icon(
      onPressed: carregando ? null : onPressed,
      icon: icone == null ? const SizedBox.shrink() : Icon(icone, size: 18),
      label: conteudo,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icone,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icone;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icone == null ? null : Icon(icone, size: 20),
          ),
        ),
      ],
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.titulo, {super.key, this.acao, this.subtitulo});

  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titulo, style: AppTextStyles.section),
                if (subtitulo != null)
                  Text(subtitulo!, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.mensagem,
    this.icone = Icons.inbox_outlined,
    this.acao,
  });

  final String mensagem;
  final IconData icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icone, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            if (acao != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}

class GradeCards extends StatelessWidget {
  const GradeCards({super.key, required this.itens, this.colunasDesktop = 4});

  final List<Widget> itens;
  final int colunasDesktop;

  @override
  Widget build(BuildContext context) {
    final int colunas = Responsivo.desktop(context)
        ? colunasDesktop
        : Responsivo.colunas(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double largura =
            (constraints.maxWidth - (colunas - 1) * AppSpacing.md) / colunas;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (final Widget item in itens)
              SizedBox(width: largura, child: item),
          ],
        );
      },
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.escuro = false, this.compacto = false});

  final bool escuro;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final Widget marca = Container(
      height: compacto ? 36 : 40,
      width: compacto ? 36 : 40,
      decoration: BoxDecoration(
        color: escuro ? AppColors.sidebar : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(
        Icons.pets,
        size: compacto ? 18 : 20,
        color: escuro ? Colors.white : AppColors.sidebar,
      ),
    );

    if (compacto) return marca;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        marca,
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Ferret',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: escuro ? AppColors.textPrimary : Colors.white,
              ),
            ),
            Text(
              'BI PLATFORM',
              style: AppTextStyles.overline.copyWith(
                fontSize: 10,
                letterSpacing: 1.4,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FundoMarca extends StatelessWidget {
  const FundoMarca({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.brandTop, AppColors.brandBottom],
        ),
      ),
      child: CustomPaint(painter: _GradePainter(), child: child),
    );
  }
}

class _GradePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linha = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const double passo = 44;
    for (double x = 0; x < size.width; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linha);
    }
    for (double y = 0; y < size.height; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linha);
    }

    final Offset centro = Offset(size.width * 0.75, size.height * 0.25);
    final double raio = size.height * 0.4;
    canvas.drawCircle(
      centro,
      raio,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            AppColors.accent.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: raio)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChipMarca extends StatelessWidget {
  const ChipMarca(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, color: AppColors.accent),
      ),
    );
  }
}

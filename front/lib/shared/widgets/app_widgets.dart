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
      // As marcas ficam dentro do Material para terem exatamente o tamanho do card.
      child: CustomPaint(
        foregroundPainter: const _CantosPainter(),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// Marcas de registro nos quatro cantos do card: um traço curto e mais escuro
/// sobre a borda, como nas molduras de um painel técnico.
class _CantosPainter extends CustomPainter {
  const _CantosPainter();

  static const double _tamanho = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint traco = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 1;
    // A borda do card é desenhada por cima do conteúdo, então as marcas ficam
    // 1,5 px para dentro, encostadas nela.
    const double m = 1.5;
    final double w = size.width - m;
    final double h = size.height - m;

    for (final (double x, double y, double dx, double dy) in <(double, double, double, double)>[
      (m, m, 1, 1),
      (w, m, -1, 1),
      (m, h, 1, -1),
      (w, h, -1, -1),
    ]) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * _tamanho, y), traco);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * _tamanho), traco);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Faixa de listras diagonais usada como separador, no lugar de uma linha lisa.
class Hachura extends StatelessWidget {
  const Hachura({super.key, this.altura = 8});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: const ClipRect(child: CustomPaint(painter: _HachuraPainter())),
    );
  }
}

class _HachuraPainter extends CustomPainter {
  const _HachuraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint traco = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 5) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), traco);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(icone, size: 14, color: destaque),
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
                Text(titulo.toUpperCase(), style: AppTextStyles.section),
                if (subtitulo != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitulo!, style: AppTextStyles.caption),
                ],
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

class TagFiltro extends StatelessWidget {
  const TagFiltro({
    super.key,
    required this.texto,
    required this.ativa,
    required this.onTap,
  });

  final String texto;
  final bool ativa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: ativa ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: 6,
            ),
            child: Text(
              texto,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: ativa ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
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

/// Caminhos das imagens de logo. Os arquivos ficam em front/assets/logos/.
/// Enquanto um arquivo não existir, o app mostra uma marca desenhada no lugar.
class AppLogos {
  const AppLogos._();

  static const String ferret = 'assets/logos/ferret.png';
  static const String scs = 'assets/logos/scs.png';
}

/// Logo do Ferret: a imagem (ou a marca reserva) e o nome ao lado.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.escuro = false, this.compacto = false});

  /// Mantido para as telas que já passam este parâmetro. Com o tema claro, o
  /// logo tem a mesma aparência nos dois casos.
  final bool escuro;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final double lado = compacto ? 36 : 40;

    final Widget marca = SizedBox(
      height: lado,
      width: lado,
      child: Image.asset(
        AppLogos.ferret,
        fit: BoxFit.contain,
        errorBuilder: (BuildContext _, Object __, StackTrace? ___) => Container(
          alignment: Alignment.center,
          color: AppColors.ink,
          child: Text(
            'F',
            style: TextStyle(
              fontSize: compacto ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
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
            const Text(
              '[FERRET]',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: 1.0,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'BI PLATFORM',
              style: AppTextStyles.overline.copyWith(
                fontSize: 9.5,
                letterSpacing: 1.6,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Logo da Prefeitura de São Caetano do Sul, com a legenda da secretaria.
class LogoScs extends StatelessWidget {
  const LogoScs({super.key, this.altura = 34, this.comLegenda = true});

  final double altura;
  final bool comLegenda;

  @override
  Widget build(BuildContext context) {
    final Widget imagem = SizedBox(
      height: altura,
      child: Image.asset(
        AppLogos.scs,
        fit: BoxFit.contain,
        errorBuilder: (BuildContext _, Object __, StackTrace? ___) => Container(
          height: altura,
          width: altura,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.ink)),
          child: const Text(
            'SCS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );

    if (!comLegenda) return imagem;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        imagem,
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'SÃO CAETANO DO SUL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'SEMOB · MOBILIDADE URBANA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.overline.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fundo do painel de marca (tela de login): grade técnica e uma mira.
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
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: CustomPaint(painter: const _GradePainter(), child: child),
    );
  }
}

class _GradePainter extends CustomPainter {
  const _GradePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linha = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const double passo = 44;
    for (double x = 0; x < size.width; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linha);
    }
    for (double y = 0; y < size.height; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linha);
    }

    // Mira: duas linhas que cruzam a tela, um círculo tracejado e os quatro
    // cantos de uma moldura em volta do ponto.
    final Offset centro = Offset(size.width * 0.76, size.height * 0.17);
    final Paint mira = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, centro.dy), Offset(size.width, centro.dy), linha);
    canvas.drawLine(Offset(centro.dx, 0), Offset(centro.dx, size.height), linha);

    const double raio = 46;
    const int tracos = 28;
    for (int i = 0; i < tracos; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: raio),
        i * 2 * 3.141592653589793 / tracos,
        2 * 3.141592653589793 / tracos,
        false,
        mira,
      );
    }

    const double meio = 78;
    const double canto = 22;
    for (final (double sx, double sy) in <(double, double)>[
      (-1, -1),
      (1, -1),
      (-1, 1),
      (1, 1),
    ]) {
      final Offset p = centro + Offset(sx * meio, sy * meio);
      canvas.drawLine(p, p - Offset(sx * canto, 0), mira);
      canvas.drawLine(p, p - Offset(0, sy * canto), mira);
    }

    canvas.drawRect(
      Rect.fromCenter(center: centro, width: 6, height: 6),
      Paint()..color = AppColors.accent,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        texto.toUpperCase(),
        style: AppTextStyles.overline.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

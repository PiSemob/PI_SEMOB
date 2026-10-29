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
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Quando informado, o card inteiro vira clicável.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget conteudo = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg - 4),
      child: child,
    );

    // Painel plano com filete: a hierarquia vem do espaço e da tipografia,
    // não de sombras.
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: onTap == null ? conteudo : InkWell(onTap: onTap, child: conteudo),
    );
  }
}

/// Separador fino. O nome foi mantido porque as telas já o usam.
class Hachura extends StatelessWidget {
  const Hachura({super.key, this.altura = 1});

  final double altura;

  @override
  Widget build(BuildContext context) => Divider(height: altura);
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (icone != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Icon(icone, size: 18, color: cor ?? AppColors.secondary),
              ],
            ],
          ),
          const SizedBox(height: 12),
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

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '${positiva ? '▲' : '▼'} '
                '${valor.abs().toStringAsFixed(1).replaceAll('.', ',')}%',
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: '  $label'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption,
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
    this.compacto = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool secundario;
  final bool carregando;

  /// Botão do tamanho do texto (barras e cabeçalhos), em vez de ocupar a
  /// largura toda como nos formulários.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final Size? tamanho = compacto ? const Size(0, 38) : null;
    final EdgeInsets? recuo =
        compacto ? const EdgeInsets.symmetric(horizontal: 14) : null;
    final Widget conteudo = carregando
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    final Widget? icon = icone == null ? null : Icon(icone, size: 18);

    if (secundario) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: tamanho, padding: recuo),
        onPressed: carregando ? null : onPressed,
        icon: icon,
        label: conteudo,
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: tamanho, padding: recuo),
      onPressed: carregando ? null : onPressed,
      icon: icon,
      label: conteudo,
    );
  }
}

class AppTextField extends StatefulWidget {
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

  /// Campo de senha. Ganha um botão para mostrar ou ocultar o texto.
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _oculto = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _oculto,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                widget.icone == null ? null : Icon(widget.icone, size: 19),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _oculto ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(
                      _oculto
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
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
            Icon(icone, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 12),
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
    final BorderRadius raio = BorderRadius.circular(AppSpacing.radiusSm);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: ativa ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: raio,
          side: BorderSide(
            color: ativa ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: raio,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              texto,
              style: AppTextStyles.caption.copyWith(
                fontWeight: ativa ? FontWeight.w600 : FontWeight.w500,
                color: ativa ? AppColors.primary : AppColors.textSecondary,
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
    final double lado = compacto ? 32 : 34;

    final Widget marca = SizedBox(
      height: lado,
      width: lado,
      child: Image.asset(
        AppLogos.ferret,
        fit: BoxFit.contain,
        errorBuilder: (BuildContext _, Object __, StackTrace? ___) => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Text(
            'F',
            style: TextStyle(
              fontSize: 17,
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
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Ferret',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Inteligência de mobilidade',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
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
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Text(
            'SCS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.primary,
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
                style: AppTextStyles.overline.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fundo do painel de marca (tela de login): azul-claro liso.
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
          colors: <Color>[AppColors.brandTop, AppColors.fundoLogin],
        ),
      ),
      child: child,
    );
  }
}

/// Diagrama de linha no estilo da sinalização do transporte: trecho reto,
/// paradas marcadas e uma estação de integração. É a "assinatura" visual do
/// Ferret no login, ligada ao que o sistema acompanha.
class DiagramaLinha extends StatelessWidget {
  const DiagramaLinha({super.key, this.paradas = _padrao});

  static const List<String> _padrao = <String>[
    'Term. Santa Paula',
    'Centro',
    'Barcelona',
    'Cerâmica',
    'Fundação',
  ];

  final List<String> paradas;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Diagrama de linha: ${paradas.join(', ')}',
      child: SizedBox(
        height: 92,
        width: double.infinity,
        child: CustomPaint(painter: _LinhaPainter(paradas)),
      ),
    );
  }
}

class _LinhaPainter extends CustomPainter {
  const _LinhaPainter(this.paradas);

  final List<String> paradas;

  @override
  void paint(Canvas canvas, Size size) {
    const double y = 22;
    const double margem = 8;
    final double passo = (size.width - 2 * margem) / (paradas.length - 1);

    // Ramal que sai da segunda parada em 45°, como num mapa de metrô.
    final double xIntegracao = margem + passo;
    final Paint ramal = Paint()
      ..color = AppColors.chart[1]
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(xIntegracao, y)
        ..lineTo(xIntegracao + 14, y - 14)
        ..lineTo(xIntegracao + passo * 1.4, y - 14),
      ramal,
    );

    canvas.drawLine(
      const Offset(margem, y),
      Offset(size.width - margem, y),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < paradas.length; i++) {
      final double x = margem + passo * i;
      final bool terminal = i == 0 || i == paradas.length - 1;
      final bool integracao = i == 1;

      if (integracao) {
        final RRect r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y - 7), width: 14, height: 28),
          const Radius.circular(7),
        );
        canvas.drawRRect(r, Paint()..color = Colors.white);
        canvas.drawRRect(
          r,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        canvas.drawCircle(
            Offset(x, y), terminal ? 7 : 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(x, y),
          terminal ? 7 : 5,
          Paint()
            ..color = terminal ? AppColors.ink : AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = terminal ? 2.5 : 2,
        );
      }

      final TextPainter nome = TextPainter(
        text: TextSpan(
          text: paradas[i],
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 11,
            fontWeight:
                terminal || integracao ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      )..layout(maxWidth: passo - 4);
      final double dx =
          (x - nome.width / 2).clamp(0, size.width - nome.width).toDouble();
      nome.paint(canvas, Offset(dx, y + 16));
    }
  }

  @override
  bool shouldRepaint(covariant _LinhaPainter oldDelegate) =>
      oldDelegate.paradas != paradas;
}

class ChipMarca extends StatelessWidget {
  const ChipMarca(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(texto, style: AppTextStyles.caption),
    );
  }
}

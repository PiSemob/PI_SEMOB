import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg - 4),
        child: child,
      ),
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
  });

  final String mensagem;
  final IconData icone;

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

class AppLogos {
  const AppLogos._();

  static const String ferret = 'assets/logos/ferret.png';
  static const String scs = 'assets/logos/scs.png';
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compacto = false});

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

class LogoScs extends StatelessWidget {
  const LogoScs({super.key, this.altura = 34});

  final double altura;

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

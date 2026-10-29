import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/painel.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/mapa_municipio.dart';

class LayoutAcesso extends StatelessWidget {
  const LayoutAcesso({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoLogin,
      body: FundoMarca(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final bool largo = c.maxWidth >= 900;
              final Widget cartao = _Cartao(mostrarMarca: !largo, child: child);

              if (!largo) return cartao;

              return Row(
                children: <Widget>[
                  const Expanded(flex: 3, child: _PainelMarca()),
                  Expanded(flex: 2, child: cartao),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class CabecalhoAcesso extends StatelessWidget {
  const CabecalhoAcesso({super.key, required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          texto,
          style: const TextStyle(
              fontSize: 14, height: 1.45, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class AvisoAcesso extends StatelessWidget {
  const AvisoAcesso({
    super.key,
    required this.titulo,
    required this.texto,
    this.icone = Icons.info_outline,
    this.cor = AppColors.textSecondary,
  });

  final String titulo;
  final String texto;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$titulo ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: texto),
                ],
              ),
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.mostrarMarca, required this.child});

  final bool mostrarMarca;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius + 4),
            border: Border.all(color: AppColors.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                  color: AppColors.sombra,
                  blurRadius: 24,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (mostrarMarca) ...<Widget>[
                const Align(alignment: Alignment.centerLeft, child: AppLogo()),
                const SizedBox(height: AppSpacing.xl),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PainelMarca extends ConsumerWidget {
  const _PainelMarca();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Painel? painel = ref.watch(painelProvider).valueOrNull;
    final List<FluxoMapa> fluxos = painel == null
        ? const <FluxoMapa>[]
        : fluxosDasLinhas(painel, <String, int>{
            for (final LinhaOnibus l in painel.linhas) l.codigo: l.viagens,
          });

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 40, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppLogo(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'SEMOB · São Caetano do Sul',
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gestão do transporte público municipal',
            style: AppTextStyles.display,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Monitoramento, análise e apoio à decisão da operação, '
            'a partir dos dados oficiais do sistema.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: MapaMunicipio(fluxos: fluxos),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: <Widget>[
              Expanded(child: LogoScs(altura: 32)),
              Text(
                'Instituto Mauá de Tecnologia',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mapa: © colaboradores do OpenStreetMap',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

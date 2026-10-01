import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class FiltrosDemanda extends ConsumerWidget {
  const FiltrosDemanda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroDemanda filtro = ref.watch(filtroDemandaProvider);
    final FiltroDemandaNotifier notifier =
        ref.read(filtroDemandaProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text('Filtros:', style: AppTextStyles.caption),
          const SizedBox(width: AppSpacing.xs),
          _Tag(
            texto: 'Todas',
            ativa: filtro.linha == null,
            onTap: () => notifier.setLinha(null),
          ),
          for (final LinhaOnibus l in DadosExemplo.linhas)
            _Tag(
              texto: l.codigo,
              ativa: filtro.linha == l.codigo,
              onTap: () => notifier.setLinha(l.codigo),
            ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: AppColors.border,
          ),
          _Tag(
            texto: 'Todas',
            ativa: filtro.empresa == null,
            onTap: () => notifier.setEmpresa(null),
          ),
          for (final Empresa e in DadosExemplo.empresas)
            _Tag(
              texto: e.sigla,
              ativa: filtro.empresa == e.sigla,
              onTap: () => notifier.setEmpresa(e.sigla),
            ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: AppColors.border,
          ),
          _Tag(
            texto: 'Incluir finais de semana',
            ativa: !filtro.ocultarFinaisDeSemana,
            onTap: notifier.alternarFinaisDeSemana,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.texto, required this.ativa, required this.onTap});

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

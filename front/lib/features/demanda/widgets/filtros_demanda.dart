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
          const Text('Filtros:', style: AppTextStyles.caption),
          const SizedBox(width: AppSpacing.xs),
          TagFiltro(
            texto: 'Todas',
            ativa: filtro.linha == null,
            onTap: () => notifier.setLinha(null),
          ),
          for (final LinhaOnibus l in DadosExemplo.linhas)
            TagFiltro(
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
          TagFiltro(
            texto: 'Todas',
            ativa: filtro.empresa == null,
            onTap: () => notifier.setEmpresa(null),
          ),
          for (final Empresa e in DadosExemplo.empresas)
            TagFiltro(
              texto: e.sigla,
              ativa: filtro.empresa == e.sigla,
              onTap: () => notifier.setEmpresa(e.sigla),
            ),
        ],
      ),
    );
  }
}

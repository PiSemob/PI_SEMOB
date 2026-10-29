import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/painel.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class SeletorLinha extends ConsumerWidget {
  const SeletorLinha({super.key, required this.painel});

  final Painel painel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? atual = ref.watch(linhaSelecionadaProvider);
    final LinhaSelecionadaNotifier notifier =
        ref.read(linhaSelecionadaProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Text('Linha', style: AppTextStyles.label),
          ),
          TagFiltro(
              texto: 'Todas',
              ativa: atual == null,
              onTap: () => notifier.selecionar(null)),
          for (final LinhaOnibus l in painel.linhas)
            Tooltip(
              message: l.nome,
              child: TagFiltro(
                texto: l.codigo,
                ativa: atual == l.codigo,
                onTap: () => notifier.selecionar(l.codigo),
              ),
            ),
          if (atual != null && painel.linha(atual) != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child:
                  Text(painel.linha(atual)!.nome, style: AppTextStyles.caption),
            ),
        ],
      ),
    );
  }
}

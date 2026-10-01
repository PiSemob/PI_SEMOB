import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers.dart';

class FiltroPeriodoBar extends ConsumerWidget {
  const FiltroPeriodoBar({super.key, this.mostrarComparacao = true});

  final bool mostrarComparacao;

  Future<void> _escolherIntervalo(BuildContext context, WidgetRef ref) async {
    final FiltroPeriodo atual = ref.read(filtroPeriodoProvider);
    final DateTimeRange? intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: atual.inicio, end: atual.fim),
      helpText: 'Selecione o período',
      saveText: 'Aplicar',
    );
    if (intervalo != null) {
      ref.read(filtroPeriodoProvider.notifier).definirIntervalo(intervalo);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);

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
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Período:', style: AppTextStyles.caption),
          for (final PeriodoTipo tipo in PeriodoTipo.values)
            _Pilula(
              texto: tipo == PeriodoTipo.personalizado &&
                      filtro.tipo == PeriodoTipo.personalizado
                  ? filtro.descricao
                  : tipo.label,
              ativa: filtro.tipo == tipo,
              onTap: tipo == PeriodoTipo.personalizado
                  ? () => _escolherIntervalo(context, ref)
                  : () =>
                      ref.read(filtroPeriodoProvider.notifier).selecionar(tipo),
            ),
          if (mostrarComparacao) ...<Widget>[
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              color: AppColors.border,
            ),
            _Pilula(
              texto: 'Comparar períodos',
              icone: Icons.trending_up,
              ativa: filtro.comparar,
              onTap: () =>
                  ref.read(filtroPeriodoProvider.notifier).alternarComparacao(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pilula extends StatelessWidget {
  const _Pilula({
    required this.texto,
    required this.ativa,
    required this.onTap,
    this.icone,
  });

  final String texto;
  final bool ativa;
  final VoidCallback onTap;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativa ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: ativa ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icone != null) ...<Widget>[
                Icon(icone,
                    size: 15,
                    color: ativa ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                texto,
                style: AppTextStyles.label.copyWith(
                  color: ativa ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

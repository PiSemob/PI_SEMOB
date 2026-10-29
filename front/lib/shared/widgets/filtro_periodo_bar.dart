import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../painel.dart';
import '../providers.dart';

class FiltroPeriodoBar extends ConsumerWidget {
  const FiltroPeriodoBar({super.key, this.mostrarComparacao = true});

  final bool mostrarComparacao;

  Future<void> _escolherIntervalo(BuildContext context, WidgetRef ref) async {
    final FiltroPeriodo atual = ref.read(filtroPeriodoProvider);
    // Só deixa escolher dias que existem nos relatórios.
    final Painel? painel = ref.read(painelProvider).valueOrNull;
    final DateTime primeiro = painel?.inicio ?? DateTime(2023);
    final DateTime ultimo = painel?.fim ?? DateTime.now();
    DateTime dentro(DateTime d) =>
        d.isBefore(primeiro) ? primeiro : (d.isAfter(ultimo) ? ultimo : d);
    final DateTimeRange? intervalo = await showDateRangePicker(
      context: context,
      firstDate: primeiro,
      lastDate: ultimo,
      initialDateRange: DateTimeRange(start: dentro(atual.inicio), end: dentro(atual.fim)),
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
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Período', style: AppTextStyles.label),
          // Opções lado a lado num único bloco, como um seletor de sistema:
          // fica claro que só uma vale por vez.
          // No celular as opções não cabem lado a lado: rolam na horizontal.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 1),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final PeriodoTipo tipo
                          in PeriodoTipo.values) ...<Widget>[
                        if (tipo != PeriodoTipo.values.first)
                          const VerticalDivider(
                            width: 1,
                            color: AppColors.borderStrong,
                          ),
                        _Pilula(
                          texto: tipo == PeriodoTipo.personalizado &&
                                  filtro.tipo == PeriodoTipo.personalizado
                              ? filtro.descricao
                              : tipo.label,
                          icone: tipo == PeriodoTipo.personalizado
                              ? Icons.calendar_today_outlined
                              : null,
                          ativa: filtro.tipo == tipo,
                          onTap: tipo == PeriodoTipo.personalizado
                              ? () => _escolherIntervalo(context, ref)
                              : () => ref
                                  .read(filtroPeriodoProvider.notifier)
                                  .selecionar(tipo),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (mostrarComparacao)
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () =>
                  ref.read(filtroPeriodoProvider.notifier).alternarComparacao(),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Checkbox(
                      value: filtro.comparar,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => ref
                          .read(filtroPeriodoProvider.notifier)
                          .alternarComparacao(),
                    ),
                    const Text(
                      'Comparar com período anterior',
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),
            ),
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
    final Color cor = ativa ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: ativa ? AppColors.primarySoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icone != null) ...<Widget>[
                Icon(icone, size: 14, color: cor),
                const SizedBox(width: 6),
              ],
              Text(
                texto,
                style: AppTextStyles.label.copyWith(
                  color: ativa ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: ativa ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

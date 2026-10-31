import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../dados_exemplo.dart';
import '../formatters.dart';
import '../previsao.dart';
import 'app_widgets.dart';
import 'charts.dart';

class CartaoPrevisao extends ConsumerWidget {
  const CartaoPrevisao({
    super.key,
    required this.titulo,
    required this.pedido,
    this.formatarValor = fmtInteiro,
  });

  final String titulo;
  final PedidoPrevisao pedido;
  final String Function(num) formatarValor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Previsao> estado = ref.watch(previsaoProvider(pedido));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionTitle(
            titulo,
            subtitulo: switch (estado) {
              AsyncData<Previsao>(:final Previsao value) =>
                'Próximos ${value.dias.length} dias depois dos últimos dados · '
                    'modelo ${value.nomeModelo}'
                    '${value.mape == null ? '' : ' · erro médio de ${value.mape!.toStringAsFixed(1).replaceAll('.', ',')}% na validação'}',
              _ =>
                'Calculada pela API com o modelo que errou menos nesta série',
            },
          ),
          switch (estado) {
            AsyncData<Previsao>(:final Previsao value) =>
              _Conteudo(previsao: value, formatarValor: formatarValor),
            AsyncError<Previsao>(:final Object error) => Column(
                children: <Widget>[
                  EmptyState(
                    icone: Icons.cloud_off_outlined,
                    mensagem: 'Previsão indisponível.\n$error',
                  ),
                  AppButton(
                    label: 'Tentar de novo',
                    compacto: true,
                    secundario: true,
                    icone: Icons.refresh,
                    onPressed: () => ref.invalidate(previsaoProvider(pedido)),
                  ),
                ],
              ),
            _ => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          },
        ],
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.previsao, required this.formatarValor});

  final Previsao previsao;
  final String Function(num) formatarValor;

  @override
  Widget build(BuildContext context) {
    final List<DiaPrevisto> dias = previsao.dias;
    if (dias.isEmpty) {
      return const EmptyState(mensagem: 'A API não devolveu dias de previsão.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 200,
          child: GraficoLinha(
            serie: <PontoSerie>[
              for (final DiaPrevisto d in dias)
                PontoSerie(fmtDiaMes(d.data), d.previsto),
            ],
            curva: true,
            iniciarEmZero: false,
            formatarValor: formatarValor,
            nomeSerie: 'Previsto',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Previsto por dia e faixa provável (80% de chance de o valor real cair nela)',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final DiaPrevisto d in dias)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${diasSemana[d.data.weekday - 1]}, ${fmtDiaMes(d.data)}',
                      style: AppTextStyles.caption,
                    ),
                    Text(formatarValor(d.previsto), style: AppTextStyles.label),
                    Text(
                      '${formatarValor(d.minimo)} a ${formatarValor(d.maximo)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

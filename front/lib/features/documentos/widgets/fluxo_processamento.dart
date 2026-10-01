import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class FluxoProcessamento extends StatelessWidget {
  const FluxoProcessamento({super.key});

  static const List<(String, String)> _etapas =
      <(String, String)>[
    ('Receber E-mails', 'IMAP/TLS automático'),
    ('Baixar PDFs', 'Extração de anexos'),
    ('Ler & Extrair', 'OCR + Parsing IA'),
    ('Validar Dados', 'ML + Regras SEMOB'),
    ('Atualizar Dashboard', 'Push em tempo real'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool vertical = MediaQuery.sizeOf(context).width < 1000;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle(
            'Fluxo de Processamento Automático',
            subtitulo: 'Pipeline previsto para a integração com o backend',
          ),
          if (vertical)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < _etapas.length; i++) ...<Widget>[
                  _Etapa(etapa: _etapas[i], numero: i + 1),
                  if (i < _etapas.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Icon(Icons.arrow_downward,
                          size: 18, color: AppColors.textMuted),
                    ),
                ],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < _etapas.length; i++) ...<Widget>[
                    Expanded(child: _Etapa(etapa: _etapas[i], numero: i + 1)),
                    if (i < _etapas.length - 1)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Icon(Icons.arrow_forward,
                            size: 18, color: AppColors.textMuted),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({required this.etapa, required this.numero});

  final (String, String, String) etapa;
  final int numero;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(etapa.$1, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            etapa.$2,
            textAlign: TextAlign.center,
            style: AppTextStyles.label,
          ),
          Text(
            etapa.$3,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            numero.toString().padLeft(2, '0'),
            style: AppTextStyles.overline.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

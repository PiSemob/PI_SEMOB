import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class RelatoriosPage extends ConsumerStatefulWidget {
  const RelatoriosPage({super.key});

  @override
  ConsumerState<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends ConsumerState<RelatoriosPage> {
  int _modelo = 0;

  void _avisar(String acao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$acao será habilitado quando o backend do Ferret estiver pronto.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ModeloRelatorio selecionado = DadosExemplo.modelosRelatorio[_modelo];

    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(mostrarComparacao: false),
      children: <Widget>[
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle(
                'Modelos de Relatório',
                subtitulo: 'Selecione o modelo e gere automaticamente com IA',
              ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final int colunas = c.maxWidth < 700 ? 1 : (c.maxWidth < 1100 ? 2 : 4);
                  final double largura =
                      (c.maxWidth - (colunas - 1) * AppSpacing.md) / colunas;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      for (int i = 0;
                          i < DadosExemplo.modelosRelatorio.length;
                          i++)
                        SizedBox(
                          width: largura,
                          child: _CardModelo(
                            modelo: DadosExemplo.modelosRelatorio[i],
                            selecionado: _modelo == i,
                            onTap: () => setState(() => _modelo = i),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(selecionado.icone, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(selecionado.nome, style: AppTextStyles.section),
                        const Text(
                          '15 de setembro de 2026 · SEMOB-SCS',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),
                    onPressed: () => _avisar('A geração com IA'),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Gerar com IA'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: EmptyState(
                  icone: Icons.insert_chart_outlined,
                  mensagem: 'Pronto para gerar\n'
                      'Clique em "Gerar com IA" para criar o '
                      '${selecionado.nome} automaticamente com os dados '
                      'mais recentes.',
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle('Formatos de Exportação'),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final int colunas = c.maxWidth < 700 ? 1 : 3;
                  final double largura =
                      (c.maxWidth - (colunas - 1) * AppSpacing.md) / colunas;
                  const List<(String, String)> formatos =
                      <(String, String)>[
                    (
                      'PDF',
                      'Relatório formatado para impressão e arquivamento'
                    ),
                    ('Excel', 'Dados e gráficos em planilha editável'),
                    (
                      'CSV',
                      'Dados brutos para integração com outros sistemas'
                    ),
                  ];
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      for (final (String, String) f in formatos)
                        SizedBox(
                          width: largura,
                          child: _CardFormato(
                            formato: f,
                            onTap: () => _avisar('A exportação em ${f.$1}'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardModelo extends StatelessWidget {
  const _CardModelo({
    required this.modelo,
    required this.selecionado,
    required this.onTap,
  });

  final ModeloRelatorio modelo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selecionado ? AppColors.primary : AppColors.border,
              width: selecionado ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(modelo.icone, style: const TextStyle(fontSize: 20)),
                  const Spacer(),
                  if (selecionado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        'SELECIONADO',
                        style: AppTextStyles.overline
                            .copyWith(color: Colors.white, fontSize: 9),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(modelo.nome, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.xs),
              Text(modelo.descricao, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFormato extends StatelessWidget {
  const _CardFormato({required this.formato, required this.onTap});

  final (String, String) formato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(formato.$1, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.xs),
              Text(formato.$2, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

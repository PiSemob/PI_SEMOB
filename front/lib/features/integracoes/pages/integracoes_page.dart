import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';

class IntegracoesPage extends ConsumerWidget {
  const IntegracoesPage({super.key});

  static Color _corStatus(String status) => switch (status) {
        'Conectado' => AppColors.accent,
        'Pendente' => AppColors.warning,
        _ => AppColors.danger,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FonteDados> fontes = DadosExemplo.fontesDados;
    int contar(String s) => fontes.where((FonteDados f) => f.status == s).length;

    return PaginaConteudo(
      children: <Widget>[
        GradeCards(
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Fontes de dados',
              valor: '${fontes.length}',
              icone: Icons.hub_outlined,
            ),
            AppMetricCard(
              titulo: 'Conectadas',
              valor: '${contar('Conectado')}',
              icone: Icons.link,
              cor: AppColors.accent,
            ),
            AppMetricCard(
              titulo: 'Com erro',
              valor: '${contar('Erro')}',
              icone: Icons.link_off,
              cor: AppColors.danger,
            ),
            const AppMetricCard(
              titulo: 'Última atualização',
              valor: '09:55',
              icone: Icons.update,
              cor: AppColors.teal,
              detalhe: '15/09/2026',
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle(
                'Fontes de Dados e Integrações',
                subtitulo: 'Status das conexões que alimentam o Ferret BI',
              ),
              for (final FonteDados f in fontes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CardFonte(fonte: f, cor: _corStatus(f.status)),
                ),
            ],
          ),
        ),
        const _Arquitetura(),
      ],
    );
  }
}

class _CardFonte extends StatelessWidget {
  const _CardFonte({required this.fonte, required this.cor});

  final FonteDados fonte;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final bool estreito = MediaQuery.sizeOf(context).width < 900;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(fonte.icone, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        fonte.nome,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        fonte.status,
                        style: AppTextStyles.caption
                            .copyWith(color: cor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${fonte.protocolo} · ${fonte.detalhe}',
                  style: AppTextStyles.caption,
                ),
                if (fonte.erro != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        fonte.erro!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.danger),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!estreito) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text('Última sync', style: AppTextStyles.overline),
                Text(fonte.ultimaSync, style: AppTextStyles.caption),
              ],
            ),
          ],
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sincronização de "${fonte.nome}" será habilitada com o backend.',
                ),
              ),
            ),
            child: Text(fonte.status == 'Erro' ? 'Reconectar' : 'Sincronizar'),
          ),
        ],
      ),
    );
  }
}

/// Diagrama Fontes -> Ferret BI -> Saidas.
class _Arquitetura extends StatelessWidget {
  const _Arquitetura();

  static const List<(String, List<String>)> _colunas =
      <(String, List<String>)>[
    ('FONTES', <String>['GPS / AVL', 'Bilhetagem', 'E-mails/PDF', 'APIs Externas']),
    (
      'FERRET BI',
      <String>[
        'Ingestão',
        'Processamento ML',
        'Análise IA',
        'Geração de Dashboards',
      ]
    ),
    ('SAÍDAS', <String>['Dashboard BI', 'Alertas', 'Relatórios IA', 'MOBI AI']),
  ];

  @override
  Widget build(BuildContext context) {
    final bool vertical = MediaQuery.sizeOf(context).width < 900;

    final List<Widget> blocos = <Widget>[
      for (int i = 0; i < _colunas.length; i++) ...<Widget>[
        if (vertical)
          _Coluna(dados: _colunas[i], destaque: i == 1)
        else
          Expanded(child: _Coluna(dados: _colunas[i], destaque: i == 1)),
        if (i < _colunas.length - 1)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: vertical ? 0 : AppSpacing.md,
              vertical: vertical ? AppSpacing.sm : 0,
            ),
            child: Icon(
              vertical ? Icons.arrow_downward : Icons.arrow_forward,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
      ],
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle(
            'Arquitetura de Dados',
            subtitulo: 'Do dado bruto ao indicador na tela',
          ),
          if (vertical)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocos)
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: blocos,
              ),
            ),
        ],
      ),
    );
  }
}

class _Coluna extends StatelessWidget {
  const _Coluna({required this.dados, required this.destaque});

  final (String, List<String>) dados;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: destaque
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: destaque ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            dados.$1,
            style: AppTextStyles.overline.copyWith(
              color: destaque ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final String item in dados.$2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 5,
                    width: 5,
                    decoration: BoxDecoration(
                      color: destaque ? AppColors.primary : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

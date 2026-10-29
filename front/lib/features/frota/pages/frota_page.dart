import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class FrotaPage extends ConsumerStatefulWidget {
  const FrotaPage({super.key});

  @override
  ConsumerState<FrotaPage> createState() => _FrotaPageState();
}

class _FrotaPageState extends ConsumerState<FrotaPage> {
  String? _linha;

  static Color corStatus(String status) => switch (status) {
        'Em rota' => AppColors.accent,
        'Atenção' => AppColors.warning,
        _ => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final List<Veiculo> veiculos = _linha == null
        ? DadosExemplo.veiculos
        : DadosExemplo.veiculos
            .where((Veiculo v) => v.linha == _linha)
            .toList();

    return PaginaConteudo(
      barraSuperior: const FiltroPeriodoBar(mostrarComparacao: false),
      children: <Widget>[
        const GradeCards(
          colunasDesktop: 5,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'Veículos ativos',
              valor: '42',
              icone: Icons.directions_bus_outlined,
              cor: AppColors.accent,
            ),
            AppMetricCard(
              titulo: 'Em manutenção',
              valor: '6',
              icone: Icons.build_outlined,
              cor: AppColors.warning,
            ),
            AppMetricCard(
              titulo: 'Linhas em operação',
              valor: '8',
              icone: Icons.alt_route_outlined,
            ),
            AppMetricCard(
              titulo: 'Linhas em alerta',
              valor: '3',
              icone: Icons.warning_amber_rounded,
              cor: AppColors.danger,
            ),
            AppMetricCard(
              titulo: 'Velocidade média',
              valor: '38 km/h',
              icone: Icons.speed_outlined,
              cor: AppColors.teal,
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle('Linhas'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _linha == null,
                    onSelected: (_) => setState(() => _linha = null),
                  ),
                  for (final LinhaOnibus l in DadosExemplo.linhas)
                    ChoiceChip(
                      label: Text(l.codigo),
                      selected: _linha == l.codigo,
                      onSelected: (_) => setState(() => _linha = l.codigo),
                    ),
                ],
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            const Widget mapa = _AreaMapa();
            final Widget lista = _ListaVeiculos(veiculos: veiculos);

            if (c.maxWidth < 1000) {
              return Column(
                children: <Widget>[
                  mapa,
                  const SizedBox(height: AppSpacing.md),
                  lista,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(flex: 3, child: mapa),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: lista),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AreaMapa extends StatelessWidget {
  const _AreaMapa();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionTitle(
            'GPS ao vivo',
            subtitulo: 'São Caetano do Sul, SP',
            acao: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Legenda(cor: AppColors.accent, texto: 'Em rota'),
                SizedBox(width: AppSpacing.md),
                _Legenda(cor: AppColors.warning, texto: 'Atenção'),
                SizedBox(width: AppSpacing.md),
                _Legenda(cor: AppColors.danger, texto: 'Parado'),
              ],
            ),
          ),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: const EmptyState(
              icone: Icons.map_outlined,
              mensagem: 'Configure a HERE Maps API Key em Configurações '
                  'para exibir o mapa real.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(texto, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ListaVeiculos extends StatelessWidget {
  const _ListaVeiculos({required this.veiculos});

  final List<Veiculo> veiculos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionTitle(
            'Veículos',
            subtitulo: '${veiculos.length} em monitoramento',
          ),
          if (veiculos.isEmpty)
            const EmptyState(mensagem: 'Nenhum veículo nessa linha.')
          else
            for (final Veiculo v in veiculos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 34,
                      width: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.directions_bus_outlined,
                          size: 18, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('${v.linha} · ${v.prefixo}',
                              style: AppTextStyles.label),
                          Text('→ ${v.destino}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _FrotaPageState.corStatus(v.status)
                            .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        v.status,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _FrotaPageState.corStatus(v.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

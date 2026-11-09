import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/download/salvar_arquivo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/cartao_dados.dart';
import '../../../shared/widgets/filtro_periodo_bar.dart';

class RelatoriosPage extends ConsumerStatefulWidget {
  const RelatoriosPage({super.key});

  @override
  ConsumerState<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends ConsumerState<RelatoriosPage> {
  int _modelo = 0;
  bool _gerando = false;
  String? _exportando;
  String? _erro;

  Map<String, dynamic>? _relatorio;
  String? _chaveDoRelatorio;

  String _chave(ModeloRelatorio modelo, FiltroPeriodo filtro) =>
      '${modelo.id}|${dataParaApi(filtro.inicio)}|${dataParaApi(filtro.fim)}';

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _gerar(ModeloRelatorio modelo, FiltroPeriodo filtro) async {
    setState(() {
      _gerando = true;
      _erro = null;
    });
    try {
      final Map<String, dynamic> relatorio =
          await ref.read(apiClientProvider).gerarRelatorio(
                modelo: modelo.id,
                inicio: filtro.inicio,
                fim: filtro.fim,
              );
      if (!mounted) return;
      setState(() {
        _relatorio = relatorio;
        _chaveDoRelatorio = _chave(modelo, filtro);
      });
    } on ErroApi catch (erro) {
      if (mounted) setState(() => _erro = erro.mensagem);
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _exportar(
      String formato, ModeloRelatorio modelo, FiltroPeriodo filtro) async {
    setState(() => _exportando = formato);
    try {
      final bool gerado = _chaveDoRelatorio == _chave(modelo, filtro);
      final ArquivoBaixado arquivo =
          await ref.read(apiClientProvider).exportarRelatorio(
                modelo: modelo.id,
                inicio: filtro.inicio,
                fim: filtro.fim,
                formato: formato,
                relatorio: gerado ? _relatorio : null,
              );
      final String mensagem = await ref.read(salvarArquivoProvider)(
          arquivo.nome, arquivo.tipo, arquivo.bytes);
      if (mounted) _avisar(mensagem);
    } on ErroApi catch (erro) {
      if (mounted) _avisar('Não consegui exportar: $erro');
    } catch (erro) {
      if (mounted) _avisar('Não consegui salvar o arquivo: $erro');
    } finally {
      if (mounted) setState(() => _exportando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ModeloRelatorio selecionado = DadosExemplo.modelosRelatorio[_modelo];
    final FiltroPeriodo filtro = ref.watch(filtroPeriodoProvider);
    final Map<String, dynamic>? relatorio =
        _chaveDoRelatorio == _chave(selecionado, filtro) ? _relatorio : null;

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
                subtitulo: 'Selecione o modelo e gere com os dados do período',
              ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final int colunas =
                      c.maxWidth < 700 ? 1 : (c.maxWidth < 1100 ? 2 : 4);
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
                            onTap: () => setState(() {
                              _modelo = i;
                              _erro = null;
                            }),
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
                        Text(
                          '${filtro.descricao} · SEMOB-SCS',
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
                    onPressed:
                        _gerando ? null : () => _gerar(selecionado, filtro),
                    icon: _gerando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.description_outlined, size: 18),
                    label: Text(_gerando ? 'Gerando…' : 'Gerar relatório'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (relatorio != null)
                _PreviaRelatorio(relatorio: relatorio)
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: _erro == null
                            ? AppColors.border
                            : AppColors.danger),
                  ),
                  child: EmptyState(
                    icone: _erro == null
                        ? Icons.insert_chart_outlined
                        : Icons.error_outline,
                    mensagem: _erro != null
                        ? 'Não consegui gerar o relatório\n$_erro'
                        : _gerando
                            ? 'Gerando o ${selecionado.nome}\n'
                                'Lendo os dados tratados e rodando os modelos…'
                            : 'Pronto para gerar\n'
                                'Clique em "Gerar relatório" para criar o '
                                '${selecionado.nome} automaticamente com os dados '
                                'do período escolhido.',
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
              AppSectionTitle(
                'Formatos de Exportação',
                subtitulo: relatorio == null
                    ? '${selecionado.nome} · ${filtro.descricao}'
                    : '${selecionado.nome} · ${filtro.descricao} · com o texto gerado acima',
              ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final int colunas = c.maxWidth < 700 ? 1 : 3;
                  final double largura =
                      (c.maxWidth - (colunas - 1) * AppSpacing.md) / colunas;
                  const List<(String, String, String)> formatos =
                      <(String, String, String)>[
                    (
                      'pdf',
                      'PDF',
                      'Relatório formatado para impressão e arquivamento'
                    ),
                    ('xlsx', 'Excel', 'Dados e tabelas em planilha editável'),
                    (
                      'csv',
                      'CSV',
                      'Dados dia a dia para integração com outros sistemas'
                    ),
                  ];
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      for (final (String, String, String) f in formatos)
                        SizedBox(
                          width: largura,
                          child: _CardFormato(
                            formato: (f.$2, f.$3),
                            carregando: _exportando == f.$1,
                            onTap: _exportando != null
                                ? null
                                : () => _exportar(f.$1, selecionado, filtro),
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

class _PreviaRelatorio extends StatelessWidget {
  const _PreviaRelatorio({required this.relatorio});

  final Map<String, dynamic> relatorio;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> secoes = relatorio['secoes'] as List<dynamic>;
    final DateTime gerado = DateTime.parse(relatorio['gerado_em'] as String);
    final String hora =
        '${gerado.hour.toString().padLeft(2, '0')}:${gerado.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${relatorio['organizacao']} · ${relatorio['cidade']} · '
          'gerado em ${fmtData(gerado)} às $hora',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        SelectableText(relatorio['resumo'] as String,
            style: AppTextStyles.body),
        for (final dynamic s in secoes) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text((s as Map<String, dynamic>)['titulo'] as String,
              style: AppTextStyles.section),
          if ((s['texto'] as String? ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(s['texto'] as String, style: AppTextStyles.body),
          ],
          if ((s['indicadores'] as List<dynamic>).isNotEmpty ||
              s['tabela'] != null)
            CartaoDados(
              dados: DadosTela.deJson(
                  <String, dynamic>{...s, 'titulo': 'Números'}),
              linhasVisiveis: 8,
              aviso: 'O arquivo exportado traz todas.',
            ),
        ],
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
  const _CardFormato(
      {required this.formato, required this.onTap, this.carregando = false});

  final (String, String) formato;
  final VoidCallback? onTap;
  final bool carregando;

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
              Row(
                children: <Widget>[
                  Text(formato.$1, style: AppTextStyles.label),
                  const Spacer(),
                  if (carregando)
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.file_download_outlined,
                        size: 18, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(formato.$2, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/painel.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/faixa_indicadores.dart';
import '../../../shared/widgets/tabela_ordenavel.dart';

class AbaDocumentos extends StatefulWidget {
  const AbaDocumentos({super.key});

  @override
  State<AbaDocumentos> createState() => _AbaDocumentosState();
}

class _AbaDocumentosState extends State<AbaDocumentos> {
  String? _pasta;

  @override
  Widget build(BuildContext context) {
    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final List<String> meses = <String>{
          for (final ArquivoRelatorio a in p.arquivos) a.pasta.split('/').first,
        }.toList();
        final List<ArquivoRelatorio> arquivos = p.arquivos
            .where((ArquivoRelatorio a) =>
                _pasta == null || a.pasta.startsWith(_pasta!))
            .toList();

        return PaginaConteudo(
          children: <Widget>[
            FaixaIndicadores(
              itens: <Indicador>[
                Indicador(
                  titulo: 'Arquivos recebidos',
                  valor: fmtInteiro(p.arquivos.length),
                  detalhe: 'relatórios HTML do Smart Report',
                ),
                Indicador(
                  titulo: 'Linhas lidas',
                  valor: fmtInteiro(p.arquivos.fold<int>(
                      0, (int a, ArquivoRelatorio r) => a + r.registros)),
                  detalhe: 'somando todos os relatórios',
                ),
                Indicador(
                  titulo: 'Período coberto',
                  valor: '${fmtDiaMes(p.inicio)} a ${fmtDiaMes(p.fim)}',
                  detalhe:
                      '${p.fim.difference(p.inicio).inDays + 1} dias de operação',
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSectionTitle(
                    'Arquivos',
                    subtitulo: '${arquivos.length} em dados/brutos',
                    acao: Wrap(
                      spacing: AppSpacing.xs,
                      children: <Widget>[
                        TagFiltro(
                            texto: 'Todos',
                            ativa: _pasta == null,
                            onTap: () => setState(() => _pasta = null)),
                        for (final String m in meses)
                          TagFiltro(
                            texto: m.replaceAll('_', ' '),
                            ativa: _pasta == m,
                            onTap: () => setState(() => _pasta = m),
                          ),
                      ],
                    ),
                  ),
                  TabelaOrdenavel<ArquivoRelatorio>(
                    itens: arquivos,
                    colunas: <ColunaTabela<ArquivoRelatorio>>[
                      ColunaTabela<ArquivoRelatorio>(
                        titulo: 'Arquivo',
                        valor: (ArquivoRelatorio a) => a.arquivo,
                      ),
                      ColunaTabela<ArquivoRelatorio>(
                        titulo: 'Pasta',
                        valor: (ArquivoRelatorio a) => a.pasta,
                        texto: (ArquivoRelatorio a) =>
                            a.pasta.replaceAll('_', ' '),
                      ),
                      ColunaTabela<ArquivoRelatorio>(
                        titulo: 'Relatório',
                        valor: (ArquivoRelatorio a) => a.relatorios.join(', '),
                      ),
                      ColunaTabela<ArquivoRelatorio>(
                        titulo: 'Linhas',
                        numerica: true,
                        valor: (ArquivoRelatorio a) => a.registros,
                        texto: (ArquivoRelatorio a) => fmtInteiro(a.registros),
                      ),
                      ColunaTabela<ArquivoRelatorio>(
                        titulo: 'Gerado em',
                        valor: (ArquivoRelatorio a) => a.geradoEm,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/painel.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/tabela_ordenavel.dart';
import 'fluxo_processamento.dart';

class AbaIntegracoes extends StatelessWidget {
  const AbaIntegracoes({super.key});

  static const Map<String, String> _nomes = <String, String>{
    'viagens': 'Viagens realizadas',
    'viagens_improdutivas': 'Km improdutivo por veículo',
    'viagens_excecao': 'Viagens com problema',
    'resumo_geral': 'Resumo geral do dia',
    'resumo_linha': 'Resumo por linha',
    'partidas_faixa_horaria': 'Partidas por faixa horária',
    'resumo_faixa_horaria': 'Resumo por faixa horária',
    'fcv': 'Cumprimento de viagens (FCV)',
    'passageiros': 'Passageiros do sistema',
    'saldos': 'Saldo de créditos',
    'vendas': 'Venda × utilização',
  };

  @override
  Widget build(BuildContext context) {
    return ComPainel(
      builder: (BuildContext context, Painel p) {
        final int suspeitos =
            p.bases.fold(0, (int a, BaseDados b) => a + b.suspeitos);
        final int registros =
            p.bases.fold(0, (int a, BaseDados b) => a + b.registros);
        final ArquivoRelatorio? recente = p.arquivos.isEmpty
            ? null
            : p.arquivos.reduce((ArquivoRelatorio a, ArquivoRelatorio b) =>
                _ordem(b.geradoEm) > _ordem(a.geradoEm) ? b : a);

        return PaginaConteudo(
          children: <Widget>[
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  Icon(
                    suspeitos == 0
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color:
                        suspeitos == 0 ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text:
                                '${p.bases.length} bases com ${fmtInteiro(registros)} registros · ',
                            style: AppTextStyles.label
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                '${fmtInteiro(suspeitos)} sinalizados como suspeitos'
                                '${recente == null ? '' : ' · relatório mais recente gerado em ${recente.geradoEm}'}',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const FluxoProcessamento(),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppSectionTitle(
                    'Bases da camada limpa',
                    subtitulo:
                        'Suspeito = valor fora do comum; continua na base para conferência',
                  ),
                  TabelaOrdenavel<BaseDados>(
                    itens: p.bases,
                    ordenarPor: 2,
                    crescente: false,
                    colunas: <ColunaTabela<BaseDados>>[
                      ColunaTabela<BaseDados>(
                        titulo: 'Base',
                        valor: (BaseDados b) => _nomes[b.tabela] ?? b.tabela,
                      ),
                      ColunaTabela<BaseDados>(
                        titulo: 'Registros',
                        numerica: true,
                        valor: (BaseDados b) => b.registros,
                        texto: (BaseDados b) => fmtInteiro(b.registros),
                      ),
                      ColunaTabela<BaseDados>(
                        titulo: 'Suspeitos',
                        numerica: true,
                        valor: (BaseDados b) => b.suspeitos,
                        texto: (BaseDados b) => fmtInteiro(b.suspeitos),
                      ),
                      ColunaTabela<BaseDados>(
                        titulo: 'Período',
                        valor: (BaseDados b) => b.inicio,
                        texto: (BaseDados b) =>
                            '${fmtData(b.inicio)} a ${fmtData(b.fim)}',
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

  static int _ordem(String geradoEm) {
    final RegExpMatch? m = RegExp(r'(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2})')
        .firstMatch(geradoEm);
    if (m == null) return 0;
    return int.parse('${m[3]}${m[2]}${m[1]}${m[4]}${m[5]}');
  }
}

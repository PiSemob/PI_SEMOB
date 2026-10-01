import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/fluxo_processamento.dart';

class DocumentosPage extends ConsumerStatefulWidget {
  const DocumentosPage({super.key});

  @override
  ConsumerState<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends ConsumerState<DocumentosPage> {
  String _filtro = 'Todos';

  static Color _corStatus(String status) => switch (status) {
        'Processado' => AppColors.accent,
        'Processando' => AppColors.warning,
        _ => AppColors.danger,
      };

  static IconData _iconeStatus(String status) => switch (status) {
        'Processado' => Icons.check_circle_outline,
        'Processando' => Icons.autorenew,
        _ => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final List<DocumentoPdf> todos = DadosExemplo.documentos;
    int contar(String s) =>
        todos.where((DocumentoPdf d) => d.status == s).length;

    final List<DocumentoPdf> visiveis = _filtro == 'Todos'
        ? todos
        : todos.where((DocumentoPdf d) => d.status == _filtro).toList();

    return PaginaConteudo(
      children: <Widget>[
        GradeCards(
          colunasDesktop: 5,
          itens: <Widget>[
            AppMetricCard(
              titulo: 'PDFs recebidos',
              valor: '${todos.length}',
              icone: Icons.inbox_outlined,
            ),
            AppMetricCard(
              titulo: 'Processados',
              valor: '${contar('Processado')}',
              icone: Icons.task_alt,
              cor: AppColors.accent,
            ),
            AppMetricCard(
              titulo: 'Processando',
              valor: '${contar('Processando')}',
              icone: Icons.autorenew,
              cor: AppColors.warning,
            ),
            AppMetricCard(
              titulo: 'Com erro',
              valor: '${contar('Erro')}',
              icone: Icons.error_outline,
              cor: AppColors.danger,
            ),
            const AppMetricCard(
              titulo: 'Última sincronização',
              valor: '15/09/2026',
              icone: Icons.sync,
              cor: AppColors.teal,
              detalhe: '09:48 — IMAP/TLS',
            ),
          ],
        ),
        const FluxoProcessamento(),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppSectionTitle('Documentos'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final String s in <String>[
                    'Todos',
                    'Processado',
                    'Processando',
                    'Erro',
                  ])
                    ChoiceChip(
                      label: Text(
                        s == 'Todos'
                            ? 'Todos (${todos.length})'
                            : '$s (${contar(s)})',
                      ),
                      selected: _filtro == s,
                      onSelected: (_) => setState(() => _filtro = s),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (visiveis.isEmpty)
                const EmptyState(mensagem: 'Nenhum documento nesse status.')
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('NOME DO DOCUMENTO')),
                      DataColumn(label: Text('EMPRESA')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('DATA')),
                      DataColumn(label: Text('REGISTROS')),
                    ],
                    rows: <DataRow>[
                      for (final DocumentoPdf d in visiveis)
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Row(
                              children: <Widget>[
                                const Icon(Icons.picture_as_pdf_outlined,
                                    size: 18, color: AppColors.danger),
                                const SizedBox(width: AppSpacing.sm),
                                Text(d.arquivo),
                              ],
                            )),
                            DataCell(Text(d.empresa)),
                            DataCell(Row(
                              children: <Widget>[
                                Icon(_iconeStatus(d.status),
                                    size: 15, color: _corStatus(d.status)),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  d.status,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _corStatus(d.status),
                                  ),
                                ),
                              ],
                            )),
                            DataCell(Text(d.data)),
                            DataCell(Text(d.registros)),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

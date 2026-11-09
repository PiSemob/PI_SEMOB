import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/painel.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/cartao_dados.dart';
import '../estado_assistente.dart';

class AssistentePage extends ConsumerStatefulWidget {
  const AssistentePage({super.key});

  @override
  ConsumerState<AssistentePage> createState() => _AssistentePageState();
}

class _AssistentePageState extends ConsumerState<AssistentePage> {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _campo.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _rolarParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar([String? texto]) async {
    final String conteudo = texto ?? _campo.text;
    if (conteudo.trim().isEmpty) return;
    _campo.clear();
    final Future<void> envio =
        ref.read(assistenteProvider.notifier).enviar(conteudo);
    _rolarParaOFim();
    await envio;
    _rolarParaOFim();
  }

  @override
  Widget build(BuildContext context) {
    final EstadoAssistente estado = ref.watch(assistenteProvider);
    final bool largo = MediaQuery.sizeOf(context).width >= 900;
    final Conversa atual = estado.atual;

    return Row(
      children: <Widget>[
        if (largo) ...<Widget>[
          SizedBox(width: 260, child: _Historico(estado: estado)),
          const VerticalDivider(width: 1),
        ],
        Expanded(
          child: Column(
            children: <Widget>[
              const _CabecalhoAgente(),
              if (!largo)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: 'Nova conversa',
                    icone: Icons.add,
                    secundario: true,
                    onPressed: () =>
                        ref.read(assistenteProvider.notifier).novaConversa(),
                  ),
                ),
              Expanded(
                child: !atual.carregada
                    ? const Center(child: CircularProgressIndicator())
                    : atual.mensagens.isEmpty
                        ? _Sugestoes(onSelecionar: _enviar)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: atual.mensagens.length +
                                (estado.enviando ? 1 : 0),
                            itemBuilder: (BuildContext context, int i) =>
                                i == atual.mensagens.length
                                    ? const _Pensando()
                                    : _Balao(mensagem: atual.mensagens[i]),
                          ),
              ),
              _CampoMensagem(
                controller: _campo,
                onEnviar: _enviar,
                enviando: estado.enviando,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AvatarFerretJr extends StatelessWidget {
  const AvatarFerretJr({super.key, this.tamanho = 38});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamanho / 2),
      child: Image.asset(
        AppLogos.ferretJr,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext _, Object __, StackTrace? ___) => Container(
          width: tamanho,
          height: tamanho,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.accent]),
          ),
          child: Icon(Icons.auto_awesome,
              size: tamanho * 0.47, color: Colors.white),
        ),
      ),
    );
  }
}

class _CabecalhoAgente extends ConsumerWidget {
  const _CabecalhoAgente();

  static const List<String> _abas = <String>[
    'Análise',
    'Anomalias',
    'Previsão',
    'Relatório',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Painel? painel = ref.watch(painelProvider).valueOrNull;
    final String dados = painel == null
        ? 'Dados operacionais da SEMOB'
        : 'Dados operacionais até ${DateFormat('dd/MM/yyyy').format(painel.fim)}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          const AvatarFerretJr(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('FERRET JR', style: AppTextStyles.section),
                Text(
                  dados,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 1000)
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final String a in _abas)
                  Chip(
                      label: Text(a),
                      side: const BorderSide(color: AppColors.border)),
              ],
            ),
        ],
      ),
    );
  }
}

class _Historico extends ConsumerWidget {
  const _Historico({required this.estado});

  final EstadoAssistente estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AssistenteNotifier acoes = ref.read(assistenteProvider.notifier);
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppButton(
              label: 'Nova conversa',
              icone: Icons.add,
              secundario: true,
              onPressed: acoes.novaConversa,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                const Text('Histórico', style: AppTextStyles.caption),
                if (estado.carregando) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5)),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                itemCount: estado.conversas.length,
                itemBuilder: (BuildContext context, int i) {
                  final Conversa c = estado.conversas[i];
                  return ListTile(
                    dense: true,
                    selected: c.id == estado.selecionadaId,
                    selectedTileColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    leading: const Icon(Icons.chat_bubble_outline, size: 18),
                    title: Text(
                      c.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body,
                    ),
                    trailing: c.local && c.mensagens.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Apagar conversa',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            onPressed: () => acoes.apagar(c.id),
                          ),
                    onTap: () => acoes.selecionar(c.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sugestoes extends StatelessWidget {
  const _Sugestoes({required this.onSelecionar});

  final ValueChanged<String> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AvatarFerretJr(tamanho: 88),
              const SizedBox(height: AppSpacing.sm),
              const Text('Ferret Jr', style: AppTextStyles.title),
              const Text(
                'Pergunte sobre demanda, receita, frota, quilometragem, anomalias ou previsões.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final String s in DadosExemplo.sugestoesAssistente)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => onSelecionar(s),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(s, style: AppTextStyles.body),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pensando extends StatelessWidget {
  const _Pensando();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: AppSpacing.sm),
            Text('Ferret Jr está consultando os dados…',
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.mensagem});

  final Mensagem mensagem;

  @override
  Widget build(BuildContext context) {
    final bool usuario = mensagem.doUsuario;
    final Color fundo = usuario
        ? AppColors.primary
        : mensagem.erro
            ? AppColors.danger.withValues(alpha: 0.06)
            : AppColors.surface;
    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints:
            BoxConstraints(maxWidth: mensagem.dados.isEmpty ? 560 : 760),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(
              color: mensagem.erro ? AppColors.danger : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SelectableText(
              mensagem.texto,
              style: AppTextStyles.body.copyWith(
                color: usuario ? Colors.white : AppColors.textPrimary,
              ),
            ),
            for (final DadosTela d in mensagem.dados) CartaoDados(dados: d),
          ],
        ),
      ),
    );
  }
}

class _CampoMensagem extends StatelessWidget {
  const _CampoMensagem(
      {required this.controller,
      required this.onEnviar,
      required this.enviando});

  final TextEditingController controller;
  final VoidCallback onEnviar;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              buildCounter: (BuildContext _,
                      {required int currentLength,
                      required bool isFocused,
                      int? maxLength}) =>
                  null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              decoration: const InputDecoration(
                hintText: 'Escreva sua pergunta...',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            tooltip: 'Enviar',
            onPressed: enviando ? null : onEnviar,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

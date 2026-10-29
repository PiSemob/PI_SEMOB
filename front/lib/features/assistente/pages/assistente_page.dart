import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dados_exemplo.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_widgets.dart';

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

  void _enviar([String? texto]) {
    final String conteudo = texto ?? _campo.text;
    if (conteudo.trim().isEmpty) return;
    ref.read(assistenteProvider.notifier).enviar(conteudo);
    _campo.clear();
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

  @override
  Widget build(BuildContext context) {
    final EstadoAssistente estado = ref.watch(assistenteProvider);
    final bool largo = MediaQuery.sizeOf(context).width >= 900;

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
                child: estado.atual.mensagens.isEmpty
                    ? _Sugestoes(onSelecionar: _enviar)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: estado.atual.mensagens.length,
                        itemBuilder: (BuildContext context, int i) =>
                            _Balao(mensagem: estado.atual.mensagens[i]),
                      ),
              ),
              _CampoMensagem(controller: _campo, onEnviar: _enviar),
            ],
          ),
        ),
      ],
    );
  }
}

class _CabecalhoAgente extends StatelessWidget {
  const _CabecalhoAgente();

  static const List<String> _abas = <String>[
    'Análise',
    'Anomalias',
    'Previsão',
    'Relatório',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('FERRET JR', style: AppTextStyles.section),
                Text(
                  'Conectado · Dados operacionais de 15/09/2026',
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
                  Chip(label: Text(a), side: const BorderSide(color: AppColors.border)),
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
              onPressed: () =>
                  ref.read(assistenteProvider.notifier).novaConversa(),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Histórico', style: AppTextStyles.caption),
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
                    onTap: () =>
                        ref.read(assistenteProvider.notifier).selecionar(c.id),
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
              const Icon(Icons.smart_toy_outlined,
                  size: 40, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              const Text('Ferret Jr', style: AppTextStyles.title),
              const Text(
                'Pergunte sobre demanda, receita, frota ou quilometragem.',
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

class _Balao extends StatelessWidget {
  const _Balao({required this.mensagem});

  final Mensagem mensagem;

  @override
  Widget build(BuildContext context) {
    final bool usuario = mensagem.doUsuario;
    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: usuario ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          mensagem.texto,
          style: AppTextStyles.body.copyWith(
            color: usuario ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CampoMensagem extends StatelessWidget {
  const _CampoMensagem({required this.controller, required this.onEnviar});

  final TextEditingController controller;
  final VoidCallback onEnviar;

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
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              decoration: const InputDecoration(
                hintText: 'Escreva sua pergunta...',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: onEnviar,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

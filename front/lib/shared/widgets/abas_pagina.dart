import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class Aba {
  const Aba({required this.id, required this.titulo, required this.conteudo});

  final String id;

  final String titulo;
  final WidgetBuilder conteudo;
}

class AbasPagina extends StatefulWidget {
  const AbasPagina({super.key, required this.abas, this.inicial});

  final List<Aba> abas;

  final String? inicial;

  @override
  State<AbasPagina> createState() => _AbasPaginaState();
}

class _AbasPaginaState extends State<AbasPagina> {
  late int _indice = _indiceDe(widget.inicial);

  int _indiceDe(String? id) {
    final int i = widget.abas.indexWhere((Aba a) => a.id == id);
    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(AbasPagina antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.inicial != widget.inicial) _indice = _indiceDe(widget.inicial);
  }

  void _abrir(int i) {
    setState(() => _indice = i);
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      final Uri atual = router.routeInformationProvider.value.uri;
      router.go(Uri(
              path: atual.path,
              queryParameters: <String, String>{'aba': widget.abas[i].id})
          .toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final Aba aba = widget.abas[_indice];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < widget.abas.length; i++)
                  _BotaoAba(
                    texto: widget.abas[i].titulo,
                    selecionada: i == _indice,
                    onTap: () => _abrir(i),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
            child: KeyedSubtree(
                key: ValueKey<String>(aba.id), child: aba.conteudo(context))),
      ],
    );
  }
}

class _BotaoAba extends StatelessWidget {
  const _BotaoAba(
      {required this.texto, required this.selecionada, required this.onTap});

  final String texto;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selecionada,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2, vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selecionada ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            texto,
            style: AppTextStyles.label.copyWith(
              fontWeight: selecionada ? FontWeight.w600 : FontWeight.w500,
              color:
                  selecionada ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/autenticacao/servico_autenticacao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/layout_acesso.dart';

const int tamanhoMinimoSenha = 8;

class _Textos {
  const _Textos({
    required this.titulo,
    required this.instrucao,
    required this.campo,
    required this.salvo,
    required this.linkInvalido,
    required this.botaoInvalido,
    required this.rotaInvalido,
  });

  final String titulo;
  final String instrucao;
  final String campo;
  final String salvo;
  final String linkInvalido;
  final String botaoInvalido;
  final String rotaInvalido;
}

const _Textos _redefinicao = _Textos(
  titulo: 'Criar senha nova',
  instrucao: 'Escolha uma senha com pelo menos $tamanhoMinimoSenha caracteres.',
  campo: 'Senha nova',
  salvo: 'Pronto. Use a senha nova para entrar no Ferret.',
  linkInvalido:
      'Este link de redefinição está incompleto ou expirou. Peça um novo.',
  botaoInvalido: 'Pedir um novo link',
  rotaInvalido: '/recuperar-senha',
);

const _Textos _convite = _Textos(
  titulo: 'Boas-vindas ao Ferret',
  instrucao:
      'Crie a sua senha de acesso, com pelo menos $tamanhoMinimoSenha caracteres.',
  campo: 'Senha',
  salvo: 'Pronto. Entre no Ferret com o seu e-mail e a senha que você criou.',
  linkInvalido:
      'Este convite está incompleto ou expirou. Peça ao administrador que reenvie o convite.',
  botaoInvalido: 'Ir para o login',
  rotaInvalido: '/login',
);

class RedefinirSenhaPage extends ConsumerStatefulWidget {
  const RedefinirSenhaPage({super.key, this.token, this.convite = false});

  final String? token;
  final bool convite;

  @override
  ConsumerState<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends ConsumerState<RedefinirSenhaPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _senha = TextEditingController();
  final TextEditingController _confirmacao = TextEditingController();
  bool _salvando = false;
  bool _salvo = false;
  String? _erro;

  _Textos get _textos => widget.convite ? _convite : _redefinicao;

  @override
  void dispose() {
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await ref
          .read(servicoAutenticacaoProvider)
          .redefinirSenha(token: widget.token!, novaSenha: _senha.text);
      if (mounted) setState(() => _salvo = true);
    } on ErroAutenticacao catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro =
            'Não foi possível salvar agora. Tente de novo em instantes.');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget conteudo;
    if (widget.token == null || widget.token!.isEmpty) {
      conteudo = _Resultado(
        icone: Icons.link_off,
        cor: AppColors.warning,
        titulo: 'Link inválido',
        texto: _textos.linkInvalido,
        botao: _textos.botaoInvalido,
        rota: _textos.rotaInvalido,
      );
    } else if (_salvo) {
      conteudo = _Resultado(
        icone: Icons.check_circle_outline,
        cor: AppColors.success,
        titulo: widget.convite ? 'Senha criada' : 'Senha alterada',
        texto: _textos.salvo,
        botao: 'Ir para o login',
        rota: '/login',
      );
    } else {
      conteudo = _formulario();
    }
    return LayoutAcesso(child: conteudo);
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CabecalhoAcesso(titulo: _textos.titulo, texto: _textos.instrucao),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: _textos.campo,
            controller: _senha,
            icone: Icons.lock_outline,
            obscure: true,
            validator: (String? v) =>
                (v == null || v.length < tamanhoMinimoSenha)
                    ? 'Mínimo de $tamanhoMinimoSenha caracteres'
                    : null,
          ),
          const SizedBox(height: AppSpacing.md + 4),
          AppTextField(
            label: 'Confirme a ${_textos.campo.toLowerCase()}',
            controller: _confirmacao,
            icone: Icons.lock_outline,
            obscure: true,
            onSubmitted: (_) => _salvar(),
            validator: (String? v) =>
                v != _senha.text ? 'As senhas não são iguais' : null,
          ),
          if (_erro != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AvisoAcesso(
              titulo: 'Erro.',
              texto: _erro!,
              icone: Icons.error_outline,
              cor: AppColors.danger,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
              label: 'Salvar senha', onPressed: _salvar, carregando: _salvando),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Voltar para o login'),
          ),
        ],
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.texto,
    required this.botao,
    required this.rota,
  });

  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;
  final String botao;
  final String rota;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
            alignment: Alignment.centerLeft,
            child: Icon(icone, size: 36, color: cor)),
        const SizedBox(height: AppSpacing.md),
        CabecalhoAcesso(titulo: titulo, texto: texto),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: botao, onPressed: () => context.go(rota)),
      ],
    );
  }
}

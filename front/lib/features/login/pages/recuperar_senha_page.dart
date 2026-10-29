import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/autenticacao/servico_autenticacao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/layout_acesso.dart';
import 'login_page.dart';

class RecuperarSenhaPage extends ConsumerStatefulWidget {
  const RecuperarSenhaPage({super.key, this.email});

  final String? email;

  @override
  ConsumerState<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends ConsumerState<RecuperarSenhaPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.email);
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref
          .read(servicoAutenticacaoProvider)
          .pedirRecuperacao(_email.text.trim());
      if (mounted) setState(() => _enviado = true);
    } on ErroAutenticacao catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro =
            'Não foi possível enviar agora. Tente de novo em instantes.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutAcesso(child: _enviado ? _confirmacao() : _formulario());
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CabecalhoAcesso(
            titulo: 'Esqueci minha senha',
            texto: 'Informe seu e-mail institucional. Vamos enviar um link '
                'para você criar uma senha nova.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'E-mail institucional',
            controller: _email,
            hint: 'gestor@semob.gov.br',
            icone: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: validarEmail,
            onSubmitted: (_) => _enviar(),
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
              label: 'Enviar link', onPressed: _enviar, carregando: _enviando),
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

  Widget _confirmacao() {
    final bool demonstracao =
        ref.watch(servicoAutenticacaoProvider).demonstracao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.mark_email_read_outlined,
              size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        CabecalhoAcesso(
          titulo: 'Confira seu e-mail',
          texto:
              'Se ${_email.text.trim()} estiver cadastrado, você vai receber '
              'um link para criar uma senha nova. Veja também a caixa de spam.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
            label: 'Voltar para o login',
            onPressed: () => context.go('/login')),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Reenviar e-mail',
          secundario: true,
          carregando: _enviando,
          onPressed: _enviar,
        ),
        if (demonstracao) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AvisoAcesso(
            titulo: 'Modo demonstração.',
            texto:
                'Nenhum e-mail foi enviado. Use o botão abaixo no lugar do link.',
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.go(
              '/redefinir-senha?token=${ServicoAutenticacaoDemo.tokenDemo}',
            ),
            child: const Text('Abrir o link de redefinição'),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/autenticacao/servico_autenticacao.dart';
import '../../../core/autenticacao/sessao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/layout_acesso.dart';

String? validarEmail(String? v) =>
    (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  bool _entrando = false;
  String? _erro;

  Future<void> _entrar() async {
    if (_entrando || !_formKey.currentState!.validate()) return;
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      final Sessao sessao = await ref
          .read(servicoAutenticacaoProvider)
          .entrar(_email.text.trim(), _senha.text);
      ref.read(sessaoProvider.notifier).entrar(sessao);
      if (mounted) context.go('/dashboard');
    } on ErroAutenticacao catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível entrar agora. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  void _esqueciSenha() {
    final String email = _email.text.trim();
    context.go(
      Uri(
        path: '/recuperar-senha',
        queryParameters:
            email.isEmpty ? null : <String, String>{'email': email},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutAcesso(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CabecalhoAcesso(
              titulo: 'Entrar no Ferret',
              texto: 'Use seu e-mail institucional SEMOB-SCS.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'E-mail institucional',
              controller: _email,
              hint: 'gestor@semob.gov.br',
              icone: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: validarEmail,
            ),
            const SizedBox(height: AppSpacing.md + 4),
            AppTextField(
              label: 'Senha',
              controller: _senha,
              hint: '••••••••',
              icone: Icons.lock_outline,
              obscure: true,
              onSubmitted: (_) => _entrar(),
              validator: (String? v) =>
                  (v == null || v.length < 4) ? 'Mínimo de 4 caracteres' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _esqueciSenha,
                child: const Text('Esqueci minha senha'),
              ),
            ),
            if (_erro != null) ...<Widget>[
              AvisoAcesso(
                titulo: 'Não entrou.',
                texto: _erro!,
                icone: Icons.error_outline,
                cor: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
            ] else if (ref.read(sessaoProvider.notifier).expirada) ...<Widget>[
              const AvisoAcesso(
                titulo: 'Sessão encerrada.',
                texto: 'Sua sessão expirou. Entre de novo para continuar.',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppButton(
                label: 'Entrar', onPressed: _entrar, carregando: _entrando),
            if (ref
                .watch(servicoAutenticacaoProvider)
                .demonstracao) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              const AvisoAcesso(
                titulo: 'Modo demonstração.',
                texto: 'Qualquer e-mail e senha dão acesso ao painel.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

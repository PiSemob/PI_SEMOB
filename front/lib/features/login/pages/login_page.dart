import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers.dart';
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

  void _entrar() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(sessaoProvider.notifier).entrar(_email.text.trim());
    context.go('/dashboard');
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
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: 'Entrar', onPressed: _entrar),
            const SizedBox(height: AppSpacing.lg),
            const AvisoAcesso(
              titulo: 'Modo demonstração.',
              texto: 'Qualquer e-mail e senha dão acesso ao painel.',
            ),
          ],
        ),
      ),
    );
  }
}

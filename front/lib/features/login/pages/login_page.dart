import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/app_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool largo = c.maxWidth >= 900;

          final Widget formulario = _Formulario(
            formKey: _formKey,
            email: _email,
            senha: _senha,
            onEntrar: _entrar,
            mostrarMarca: !largo,
          );

          if (!largo) return formulario;

          return Row(
            children: <Widget>[
              const Expanded(flex: 2, child: _PainelMarca()),
              Expanded(flex: 3, child: formulario),
            ],
          );
        },
      ),
    );
  }
}

class _PainelMarca extends StatelessWidget {
  const _PainelMarca();

  static const List<String> _recursos = <String>[
    'Dashboard em tempo real',
    'IA Generativa',
    'Relatórios automáticos',
    'Rastreamento GPS',
    'Análise preditiva',
  ];

  @override
  Widget build(BuildContext context) {
    return FundoMarca(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const AppLogo(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Inteligência para o\ntransporte público',
                  style: AppTextStyles.display,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Plataforma unificada de Business Intelligence e IA '
                  'para monitoramento, análise e suporte à decisão da '
                  'operação municipal de São Caetano do Sul.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final String r in _recursos) ChipMarca(r),
                  ],
                ),
              ],
            ),
            const _CardParceiro(),
          ],
        ),
      ),
    );
  }
}

class _CardParceiro extends StatelessWidget {
  const _CardParceiro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'PARCEIRO INSTITUCIONAL',
            style: AppTextStyles.overline.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'SEMOB-SCS · Instituto Mauá de Tecnologia',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.formKey,
    required this.email,
    required this.senha,
    required this.onEntrar,
    required this.mostrarMarca,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController senha;
  final VoidCallback onEntrar;
  final bool mostrarMarca;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (mostrarMarca) ...<Widget>[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogo(escuro: true),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                const Text(
                  'Acesso à plataforma',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Use seu e-mail institucional SEMOB-SCS para entrar.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'E-mail institucional',
                  controller: email,
                  hint: 'gestor@semob.gov.br',
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? v) => (v == null || !v.contains('@'))
                      ? 'Informe um e-mail válido'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Senha',
                  controller: senha,
                  hint: '••••••••',
                  obscure: true,
                  onSubmitted: (_) => onEntrar(),
                  validator: (String? v) => (v == null || v.length < 4)
                      ? 'Mínimo de 4 caracteres'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Entrar', onPressed: onEntrar),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {},
                  child: const Text('Recuperar senha'),
                ),
                const SizedBox(height: AppSpacing.md),
                const _AvisoDemo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoDemo extends StatelessWidget {
  const _AvisoDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Modo demonstração',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Use qualquer e-mail e senha para acessar o painel demo.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

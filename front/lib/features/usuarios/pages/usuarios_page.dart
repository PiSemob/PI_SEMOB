import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/autenticacao/sessao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/secoes.dart';
import '../usuarios.dart';

final RegExp _emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class UsuariosPage extends StatelessWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaConteudo(
      children: <Widget>[_FormularioConvite(), _ListaDeUsuarios()],
    );
  }
}

class _FormularioConvite extends ConsumerStatefulWidget {
  const _FormularioConvite();

  @override
  ConsumerState<_FormularioConvite> createState() => _FormularioConviteState();
}

class _FormularioConviteState extends ConsumerState<_FormularioConvite> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool _admin = false;
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final ScaffoldMessengerState avisos = ScaffoldMessenger.of(context);
    final String email = _email.text.trim();
    setState(() => _enviando = true);
    String aviso = 'Convite enviado para $email.';
    try {
      await ref.read(apiClientProvider).convidarUsuario(
          email: email, nome: _nome.text.trim(), admin: _admin);
      _nome.clear();
      _email.clear();
      _admin = false;
    } on ErroApi catch (erro) {
      aviso = erro.mensagem;
    }
    if (!mounted) return;
    ref.invalidate(usuariosProvider);
    setState(() => _enviando = false);
    avisos.showSnackBar(SnackBar(content: Text(aviso)));
  }

  @override
  Widget build(BuildContext context) {
    return Secao(
      titulo: 'Convidar funcionário',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'A pessoa recebe um e-mail com um link para criar a própria senha. '
              'Todo usuário vê a aplicação inteira; só administradores abrem esta tela.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            DuasColunas(
              esquerda: AppTextField(
                label: 'Nome',
                controller: _nome,
                icone: Icons.person_outline,
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              direita: AppTextField(
                label: 'E-mail institucional',
                controller: _email,
                icone: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _enviar(),
                validator: (String? v) => _emailValido.hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Informe um e-mail válido',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OpcaoLigaDesliga(
              titulo: 'Administrador',
              descricao: 'Pode convidar, promover e remover usuários',
              valor: _admin,
              onChanged: (bool v) => setState(() => _admin = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: AppButton(
                  label: 'Enviar convite',
                  icone: Icons.send_outlined,
                  carregando: _enviando,
                  onPressed: _enviar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaDeUsuarios extends ConsumerWidget {
  const _ListaDeUsuarios();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? meuEmail = ref.watch(sessaoProvider)?.email;
    return ref.watch(usuariosProvider).when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object erro, _) => ErroDeCarga(
            titulo: 'Não consegui carregar os usuários',
            mensagem: erro is ErroApi ? erro.mensagem : '$erro',
            onTentarDeNovo: () => ref.invalidate(usuariosProvider),
          ),
          data: (List<UsuarioCadastrado> lista) => Secao(
            titulo: 'Usuários (${lista.length})',
            child: Column(
              children: <Widget>[
                for (int i = 0; i < lista.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _LinhaUsuario(
                      usuario: lista[i], voce: lista[i].email == meuEmail),
                ],
              ],
            ),
          ),
        );
  }
}

enum _Acao { reenviar, alternarAdmin, remover }

class _LinhaUsuario extends ConsumerWidget {
  const _LinhaUsuario({required this.usuario, required this.voce});

  final UsuarioCadastrado usuario;
  final bool voce;

  Future<bool> _confirmarRemocao(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogo) => AlertDialog(
          title: const Text('Remover acesso?'),
          content: Text(
              '${usuario.nome} (${usuario.email}) não vai mais conseguir entrar no Ferret.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogo).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogo).pop(true),
              child: const Text('Remover'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _executar(
      BuildContext context, WidgetRef ref, _Acao acao) async {
    if (acao == _Acao.remover && !await _confirmarRemocao(context)) return;
    if (!context.mounted) return;
    final ScaffoldMessengerState avisos = ScaffoldMessenger.of(context);
    final ApiClient api = ref.read(apiClientProvider);
    String aviso;
    try {
      switch (acao) {
        case _Acao.reenviar:
          await api.reenviarConvite(usuario.id);
          aviso = 'Convite reenviado para ${usuario.email}.';
        case _Acao.alternarAdmin:
          await api.definirAdministrador(usuario.id, admin: !usuario.admin);
          aviso = usuario.admin
              ? '${usuario.nome} não tem mais perfil de administrador.'
              : '${usuario.nome} agora tem perfil de administrador.';
        case _Acao.remover:
          await api.removerUsuario(usuario.id);
          aviso = 'Acesso de ${usuario.nome} removido.';
      }
      ref.invalidate(usuariosProvider);
    } on ErroApi catch (erro) {
      aviso = erro.mensagem;
    }
    avisos.showSnackBar(SnackBar(content: Text(aviso)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            usuario.nome.isEmpty ? '?' : usuario.nome[0].toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(usuario.nome, style: AppTextStyles.label),
              Text(usuario.email, style: AppTextStyles.caption),
            ],
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          children: <Widget>[
            if (voce) const _Etiqueta('Você', AppColors.secondary),
            if (usuario.admin)
              const _Etiqueta('Administrador', AppColors.primary),
            if (usuario.pendente)
              const _Etiqueta('Convite pendente', AppColors.warning),
          ],
        ),
        SizedBox(
          width: 48,
          child: voce
              ? null
              : PopupMenuButton<_Acao>(
                  tooltip: 'Ações',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (_Acao acao) => _executar(context, ref, acao),
                  itemBuilder: (_) => <PopupMenuEntry<_Acao>>[
                    if (usuario.pendente)
                      const PopupMenuItem<_Acao>(
                        value: _Acao.reenviar,
                        child: Text('Reenviar convite'),
                      ),
                    PopupMenuItem<_Acao>(
                      value: _Acao.alternarAdmin,
                      child: Text(usuario.admin
                          ? 'Tirar perfil de administrador'
                          : 'Tornar administrador'),
                    ),
                    const PopupMenuItem<_Acao>(
                      value: _Acao.remover,
                      child: Text('Remover acesso'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, this.cor);

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: cor),
      ),
      child: Text(
        texto,
        style: AppTextStyles.caption
            .copyWith(color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

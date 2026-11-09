import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/configuracoes.dart';
import '../../../shared/notificacoes.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/secoes.dart';

class ConfiguracoesPage extends ConsumerStatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  ConsumerState<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends ConsumerState<ConfiguracoesPage> {
  final TextEditingController _organizacao = TextEditingController();
  final TextEditingController _cidade = TextEditingController();
  final TextEditingController _emailRelatorios = TextEditingController();

  bool _alertas = true;
  bool _relatorios = false;
  bool _carregando = true;
  bool _salvando = false;
  String? _erroCarga;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _organizacao.dispose();
    _cidade.dispose();
    _emailRelatorios.dispose();
    super.dispose();
  }

  void _preencher(ConfiguracoesApp ajustes) {
    _organizacao.text = ajustes.organizacao;
    _cidade.text = ajustes.cidade;
    _emailRelatorios.text = ajustes.emailRelatorios;
    _alertas = ajustes.alertasAnomalia;
    _relatorios = ajustes.relatoriosAutomaticos;
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarga = null;
    });
    try {
      final Map<String, dynamic> corpo =
          await ref.read(apiClientProvider).configuracoes();
      if (mounted) setState(() => _preencher(ConfiguracoesApp.deJson(corpo)));
    } on ErroApi catch (erro) {
      if (mounted) setState(() => _erroCarga = erro.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final ConfiguracoesApp ajustes = ConfiguracoesApp(
      organizacao: _organizacao.text,
      cidade: _cidade.text,
      alertasAnomalia: _alertas,
      relatoriosAutomaticos: _relatorios,
      emailRelatorios: _emailRelatorios.text,
    );
    try {
      final Map<String, dynamic> corpo = await ref
          .read(apiClientProvider)
          .salvarConfiguracoes(ajustes.paraJson());
      if (!mounted) return;
      setState(() => _preencher(ConfiguracoesApp.deJson(corpo)));
      ref.invalidate(notificacoesProvider);
      _avisar('Configurações salvas.');
    } on ErroApi catch (erro) {
      _avisar('Não salvou: ${erro.mensagem}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erroCarga != null) {
      return ErroDeCarga(
        titulo: 'Não consegui carregar as configurações',
        mensagem: _erroCarga!,
        onTentarDeNovo: _carregar,
      );
    }
    return PaginaConteudo(
      children: <Widget>[
        const _SobreAPlataforma(),
        Secao(
          titulo: 'Organização',
          child: DuasColunas(
            esquerda: AppTextField(
                label: 'Nome da Organização', controller: _organizacao),
            direita: AppTextField(label: 'Cidade', controller: _cidade),
          ),
        ),
        Secao(
          titulo: 'Notificações',
          child: Column(
            children: <Widget>[
              OpcaoLigaDesliga(
                titulo: 'Alertas de anomalia',
                descricao:
                    'Mostrar no sino os dias atípicos apontados pelo Isolation Forest',
                valor: _alertas,
                onChanged: (bool v) => setState(() => _alertas = v),
              ),
              const Divider(height: AppSpacing.lg),
              OpcaoLigaDesliga(
                titulo: 'Relatórios automáticos',
                descricao:
                    'Envio diário do Relatório Executivo em PDF por e-mail',
                valor: _relatorios,
                onChanged: (bool v) => setState(() => _relatorios = v),
              ),
              if (_relatorios) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Enviar para',
                  hint: 'Vazio = todos os usuários cadastrados',
                  controller: _emailRelatorios,
                  icone: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 240,
            child: AppButton(
              label: 'Salvar configurações',
              icone: Icons.save_outlined,
              carregando: _salvando,
              onPressed: _salvar,
            ),
          ),
        ),
      ],
    );
  }
}

class _SobreAPlataforma extends StatelessWidget {
  const _SobreAPlataforma();

  @override
  Widget build(BuildContext context) {
    return const Secao(
      titulo: 'Sobre a Plataforma',
      child: Row(
        children: <Widget>[
          AppLogo(compacto: true),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ferret BI Platform', style: AppTextStyles.section),
                Text(
                  'Dashboard de Operação de Transporte',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'v1.0.0 · SEMOB-SCS · Instituto Mauá de Tecnologia',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

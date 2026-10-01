import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_widgets.dart';

class ConfiguracoesPage extends ConsumerStatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  ConsumerState<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends ConsumerState<ConfiguracoesPage> {
  final TextEditingController _organizacao =
      TextEditingController(text: 'SEMOB-SCS');
  final TextEditingController _cidade =
      TextEditingController(text: 'São Caetano do Sul');
  final TextEditingController _apiKey = TextEditingController();

  static const List<int> _intervalos = <int>[10, 30, 60, 300];
  static const List<int> _retencoes = <int>[30, 90, 180, 365];

  int _intervalo = 1;
  int _retencao = 1;
  bool _alertas = true;
  bool _relatorios = false;

  @override
  void dispose() {
    _organizacao.dispose();
    _cidade.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  String get _labelIntervalo {
    final int s = _intervalos[_intervalo];
    return s < 60 ? '${s}s' : '${s ~/ 60}min';
  }

  @override
  Widget build(BuildContext context) {
    return PaginaConteudo(
      children: <Widget>[
        const _SobreAPlataforma(),
        _Secao(
          titulo: 'Organização',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final bool duasColunas = c.maxWidth >= 700;
              final Widget nome = AppTextField(
                label: 'Nome da Organização',
                controller: _organizacao,
              );
              final Widget cidade = AppTextField(
                label: 'Cidade',
                controller: _cidade,
              );

              if (!duasColunas) {
                return Column(
                  children: <Widget>[
                    nome,
                    const SizedBox(height: AppSpacing.md),
                    cidade,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: nome),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cidade),
                ],
              );
            },
          ),
        ),
        _Secao(
          titulo: 'Mapa — HERE Maps API',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('API Key', style: AppTextStyles.label),
              Text(
                'Configure para ativar o rastreamento de veículos em tempo real.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Chave mascarada: no backend ela deve ficar no servidor, nunca no cliente.
              TextField(
                controller: _apiKey,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Cole a chave aqui',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Obter chave gratuita em developer.here.com',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        _Secao(
          titulo: 'Dados & Atualização',
          child: Column(
            children: <Widget>[
              _Stepper(
                titulo: 'Intervalo de atualização',
                descricao: 'Frequência de refresh do dashboard',
                valor: _labelIntervalo,
                onMenos: _intervalo > 0
                    ? () => setState(() => _intervalo--)
                    : null,
                onMais: _intervalo < _intervalos.length - 1
                    ? () => setState(() => _intervalo++)
                    : null,
              ),
              const Divider(height: AppSpacing.lg),
              _Stepper(
                titulo: 'Retenção de dados',
                descricao: 'Período de histórico armazenado',
                valor: '${_retencoes[_retencao]}d',
                onMenos:
                    _retencao > 0 ? () => setState(() => _retencao--) : null,
                onMais: _retencao < _retencoes.length - 1
                    ? () => setState(() => _retencao++)
                    : null,
              ),
            ],
          ),
        ),
        _Secao(
          titulo: 'Notificações',
          child: Column(
            children: <Widget>[
              _Switch(
                titulo: 'Alertas de anomalia',
                descricao: 'Notificar ao detectar desvios operacionais',
                valor: _alertas,
                onChanged: (bool v) => setState(() => _alertas = v),
              ),
              const Divider(height: AppSpacing.lg),
              _Switch(
                titulo: 'Relatórios automáticos',
                descricao: 'Envio diário por e-mail',
                valor: _relatorios,
                onChanged: (bool v) => setState(() => _relatorios = v),
              ),
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'As configurações serão persistidas quando o backend do '
                    'Ferret estiver disponível.',
                  ),
                ),
              ),
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
    return _Secao(
      titulo: 'Sobre a Plataforma',
      child: Row(
        children: <Widget>[
          const AppLogo(escuro: true, compacto: true),
          const SizedBox(width: AppSpacing.md),
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

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(titulo.toUpperCase(), style: AppTextStyles.overline),
          ),
          child,
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.onMenos,
    required this.onMais,
  });

  final String titulo;
  final String descricao;
  final String valor;
  final VoidCallback? onMenos;
  final VoidCallback? onMais;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titulo, style: AppTextStyles.label),
              Text(descricao, style: AppTextStyles.caption),
            ],
          ),
        ),
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          onPressed: onMenos,
          icon: const Icon(Icons.remove, size: 16),
        ),
        SizedBox(
          width: 56,
          child: Text(
            valor,
            textAlign: TextAlign.center,
            style: AppTextStyles.label,
          ),
        ),
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          onPressed: onMais,
          icon: const Icon(Icons.add, size: 16),
        ),
      ],
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.onChanged,
  });

  final String titulo;
  final String descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titulo, style: AppTextStyles.label),
              Text(descricao, style: AppTextStyles.caption),
            ],
          ),
        ),
        Switch(value: valor, onChanged: onChanged),
      ],
    );
  }
}

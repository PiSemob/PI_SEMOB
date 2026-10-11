import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../providers.dart';
import 'app_widgets.dart';

class NavItem {
  const NavItem({
    required this.rota,
    required this.label,
    required this.icone,
    required this.grupo,
    required this.titulo,
    required this.subtitulo,
    this.badge,
  });

  final String rota;
  final String label;
  final IconData icone;
  final String grupo;
  final String titulo;
  final String subtitulo;
  final String? badge;
}

const List<NavItem> navItems = <NavItem>[
  NavItem(
    rota: '/dashboard',
    label: 'Dashboard',
    icone: Icons.space_dashboard_outlined,
    grupo: 'OPERAÇÃO',
    titulo: 'Dashboard Principal',
    subtitulo: 'Visão geral da operação',
  ),
  NavItem(
    rota: '/demanda',
    label: 'Demanda',
    icone: Icons.groups_outlined,
    grupo: 'OPERAÇÃO',
    titulo: 'Módulo Demanda',
    subtitulo: 'Análise de passageiros',
  ),
  NavItem(
    rota: '/receita',
    label: 'Receita',
    icone: Icons.attach_money,
    grupo: 'FINANCEIRO',
    titulo: 'Módulo Receita',
    subtitulo: 'Arrecadação e formas de pagamento',
  ),
  NavItem(
    rota: '/creditos',
    label: 'Créditos em Circulação',
    icone: Icons.credit_card_outlined,
    grupo: 'FINANCEIRO',
    titulo: 'Créditos em Circulação',
    subtitulo: 'Venda e utilização de créditos',
  ),
  NavItem(
    rota: '/frota',
    label: 'Operação da Frota',
    icone: Icons.directions_bus_outlined,
    grupo: 'FROTA',
    titulo: 'Operação da Frota',
    subtitulo: 'Linhas, veículos e situação operacional',
  ),
  NavItem(
    rota: '/quilometragem',
    label: 'Quilometragem',
    icone: Icons.monitor_heart_outlined,
    grupo: 'FROTA',
    titulo: 'Quilometragem',
    subtitulo: 'Produção quilométrica da frota',
  ),
  NavItem(
    rota: '/documentos',
    label: 'Central de Documentos',
    icone: Icons.description_outlined,
    grupo: 'DADOS & IA',
    titulo: 'Central de Documentos',
    subtitulo: 'Recebimento e processamento de PDFs',
  ),
  NavItem(
    rota: '/assistente',
    label: 'Ferret Jr',
    icone: Icons.auto_awesome_outlined,
    grupo: 'DADOS & IA',
    titulo: 'Ferret Jr',
    subtitulo: 'Assistente inteligente da operação',
    badge: 'IA',
  ),
  NavItem(
    rota: '/relatorios',
    label: 'Relatórios',
    icone: Icons.insert_chart_outlined,
    grupo: 'DADOS & IA',
    titulo: 'Relatórios',
    subtitulo: 'Geração e exportação de relatórios',
  ),
  NavItem(
    rota: '/integracoes',
    label: 'Integrações de Dados',
    icone: Icons.hub_outlined,
    grupo: 'ADMINISTRAÇÃO',
    titulo: 'Integrações de Dados',
    subtitulo: 'Fontes de dados e status das conexões',
  ),
  NavItem(
    rota: '/configuracoes',
    label: 'Configurações',
    icone: Icons.settings_outlined,
    grupo: 'ADMINISTRAÇÃO',
    titulo: 'Configurações',
    subtitulo: 'Parâmetros do sistema',
  ),
];

const double _larguraAberta = 264;
const double _larguraEncolhida = 64;
const Duration _duracaoMenu = Duration(milliseconds: 160);

/// Verdadeiro quando a barra lateral está fixada aberta. Falso quando está
/// encolhida (só os ícones) e abre apenas enquanto o mouse está em cima.
final StateProvider<bool> sidebarFixaProvider =
    StateProvider<bool>((ref) => true);

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.rotaAtual});

  final Widget child;
  final String rotaAtual;

  int get _indice {
    final int i =
        navItems.indexWhere((NavItem n) => rotaAtual.startsWith(n.rota));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool largo = MediaQuery.sizeOf(context).width >= 900;
    final NavItem atual = navItems[_indice];

    if (largo) {
      final bool fixa = ref.watch(sidebarFixaProvider);
      return Scaffold(
        // A barra fica por cima do conteúdo. Encolhida, ela ocupa só a faixa
        // dos ícones; ao abrir com o mouse, cobre parte da tela sem empurrar
        // os gráficos.
        body: Stack(
          children: <Widget>[
            AnimatedPadding(
              duration: _duracaoMenu,
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: fixa ? _larguraAberta : _larguraEncolhida,
              ),
              child: Column(
                children: <Widget>[
                  _Header(item: atual),
                  Expanded(child: child),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _Sidebar(indice: _indice),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(atual.titulo, style: AppTextStyles.title),
            Text(atual.subtitulo, style: AppTextStyles.caption),
          ],
        ),
        actions: const <Widget>[_BadgeAoVivo(), SizedBox(width: AppSpacing.md)],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.sidebar,
        child: _Sidebar(indice: _indice, dentroDoDrawer: true),
      ),
      body: child,
    );
  }
}

class _Sidebar extends ConsumerStatefulWidget {
  const _Sidebar({required this.indice, this.dentroDoDrawer = false});

  final int indice;
  final bool dentroDoDrawer;

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  bool _mouseEmCima = false;

  void _irPara(NavItem item) {
    if (widget.dentroDoDrawer) Navigator.of(context).pop();
    context.go(item.rota);
  }

  void _alternarFixa(bool fixa) {
    ref.read(sidebarFixaProvider.notifier).state = !fixa;
    // Ao encolher, fecha na hora, mesmo com o mouse ainda sobre o botão.
    if (fixa) setState(() => _mouseEmCima = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dentroDoDrawer) {
      return ColoredBox(color: AppColors.sidebar, child: _aberta(fixa: null));
    }

    final bool fixa = ref.watch(sidebarFixaProvider);
    final bool aberta = fixa || _mouseEmCima;
    final double largura = aberta ? _larguraAberta : _larguraEncolhida;

    return MouseRegion(
      onEnter: (_) => setState(() => _mouseEmCima = true),
      onExit: (_) => setState(() => _mouseEmCima = false),
      child: AnimatedContainer(
        duration: _duracaoMenu,
        curve: Curves.easeOut,
        width: largura,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.sidebar,
          border: const Border(right: BorderSide(color: AppColors.border)),
          // Sombra só quando a barra está aberta por cima do conteúdo.
          boxShadow: aberta && !fixa
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(4, 0),
                  ),
                ]
              : null,
        ),
        // O conteúdo é desenhado já na largura final e a barra o recorta
        // enquanto anima. Sem isso, os textos quebrariam durante a animação.
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: largura,
          maxWidth: largura,
          child: aberta ? _aberta(fixa: fixa) : _encolhida(),
        ),
      ),
    );
  }

  /// Só o logo do Ferret e os ícones.
  Widget _encolhida() {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: AppLogo(compacto: true),
        ),
        const Hachura(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: <Widget>[
              for (int i = 0; i < navItems.length; i++)
                _ItemNavIcone(
                  item: navItems[i],
                  selecionado: i == widget.indice,
                  onTap: () => _irPara(navItems[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Barra completa. `fixa` nulo significa "dentro do menu do celular", onde
  /// não há botão de encolher.
  Widget _aberta({required bool? fixa}) {
    final String? usuario = ref.watch(sessaoProvider);

    final List<Widget> itens = <Widget>[];
    String? grupoAnterior;
    for (int i = 0; i < navItems.length; i++) {
      final NavItem n = navItems[i];
      if (n.grupo != grupoAnterior) {
        grupoAnterior = n.grupo;
        itens.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              '[${n.grupo}]',
              style: AppTextStyles.overline.copyWith(color: AppColors.textMuted),
            ),
          ),
        );
      }
      itens.add(
        _ItemNav(
          item: n,
          selecionado: i == widget.indice,
          onTap: () => _irPara(n),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppLogo(),
                ),
              ),
              if (fixa != null)
                IconButton(
                  tooltip: fixa ? 'Encolher menu' : 'Fixar menu aberto',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    fixa
                        ? Icons.keyboard_double_arrow_left
                        : Icons.push_pin_outlined,
                    size: 18,
                    color: AppColors.sidebarText,
                  ),
                  onPressed: () => _alternarFixa(fixa),
                ),
            ],
          ),
        ),
        const Hachura(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: itens,
          ),
        ),
        const Hachura(),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: LogoScs(),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                height: 34,
                width: 34,
                alignment: Alignment.center,
                color: AppColors.ink,
                child: const Text(
                  'GS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'GESTOR SEMOB',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      usuario ?? 'gestor@semob.gov.br',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.sidebarText),
                    ),
                  ],
                ),
              ),
              const _BotaoSair(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Item do menu encolhido: só o ícone, com a mesma barra laranja de seleção.
class _ItemNavIcone extends StatelessWidget {
  const _ItemNavIcone({
    required this.item,
    required this.selecionado,
    required this.onTap,
  });

  final NavItem item;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? AppColors.sidebarActive : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: selecionado ? AppColors.accent : Colors.transparent,
              ),
            ),
          ),
          child: Icon(
            item.icone,
            size: 18,
            color: selecionado ? AppColors.textPrimary : AppColors.sidebarText,
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({
    required this.item,
    required this.selecionado,
    required this.onTap,
  });

  final NavItem item;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color cor =
        selecionado ? AppColors.textPrimary : AppColors.sidebarText;

    return Material(
      color: selecionado ? AppColors.sidebarActive : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.isEmpty
              ? null
              : (selecionado ? AppColors.sidebarActive : AppColors.sidebarHover),
        ),
        child: Container(
          // A barra laranja à esquerda marca o item atual.
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: selecionado ? AppColors.accent : Colors.transparent,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(13, 10, AppSpacing.md, 10),
          child: Row(
            children: <Widget>[
              Icon(item.icone, size: 16, color: cor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 0.8,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
                    color: cor,
                  ),
                ),
              ),
              if (item.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.accent,
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
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

class _Header extends StatelessWidget {
  const _Header({required this.item});

  final NavItem item;

  /// 'DADOS & IA' vira 'Dados & ia': só a primeira letra fica maiúscula.
  static String _capitalizar(String texto) => texto.isEmpty
      ? texto
      : texto[0].toUpperCase() + texto.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final bool compacto = MediaQuery.sizeOf(context).width < 1250;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          // Caminho no estilo "Ferret/Operação/Dashboard", como em um terminal.
          Text(
            'Ferret/${_capitalizar(item.grupo)}/',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          Text(item.titulo, style: AppTextStyles.title),
          const SizedBox(width: AppSpacing.md),
          Container(width: 1, height: 18, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.subtitulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
          const _BadgeAoVivo(),
          if (!compacto) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            Text(
              DateFormat('dd/MM/yyyy  HH:mm').format(DateTime.now()),
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Notificações',
            icon: const Icon(Icons.notifications_none,
                size: 20, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            onPressed: () => context.go('/relatorios'),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Exportar'),
          ),
        ],
      ),
    );
  }
}

class _BadgeAoVivo extends StatelessWidget {
  const _BadgeAoVivo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(height: 6, width: 6, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'AO VIVO',
            style: AppTextStyles.overline.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _BotaoSair extends ConsumerWidget {
  const _BotaoSair();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sair',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.logout, size: 18, color: AppColors.sidebarText),
      onPressed: () {
        ref.read(sessaoProvider.notifier).sair();
        context.go('/login');
      },
    );
  }
}

class PaginaConteudo extends StatelessWidget {
  const PaginaConteudo({super.key, required this.children, this.barraSuperior});

  final List<Widget> children;
  final Widget? barraSuperior;

  @override
  Widget build(BuildContext context) {
    final double padding =
        MediaQuery.sizeOf(context).width < 700 ? AppSpacing.md : AppSpacing.lg;

    final Widget scroll = SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final Widget w in children) ...<Widget>[
                w,
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );

    if (barraSuperior == null) return scroll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[barraSuperior!, Expanded(child: scroll)],
    );
  }
}

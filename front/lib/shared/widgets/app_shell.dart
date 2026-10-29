import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../painel.dart';
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
    label: 'Visão geral',
    icone: Icons.space_dashboard_outlined,
    grupo: 'PAINÉIS',
    titulo: 'Dashboard Principal',
    subtitulo: 'Visão geral da operação',
  ),
  NavItem(
    rota: '/operacao',
    label: 'Operação',
    icone: Icons.directions_bus_outlined,
    grupo: 'PAINÉIS',
    titulo: 'Operação',
    subtitulo: 'Demanda, operação da frota e quilometragem',
  ),
  NavItem(
    rota: '/receita',
    label: 'Financeiro',
    icone: Icons.payments_outlined,
    grupo: 'PAINÉIS',
    titulo: 'Financeiro',
    subtitulo: 'Receita e créditos em circulação',
  ),
  NavItem(
    rota: '/dados',
    label: 'Dados e relatórios',
    icone: Icons.description_outlined,
    grupo: 'PAINÉIS',
    titulo: 'Dados e Relatórios',
    subtitulo: 'Documentos, integrações e relatórios',
  ),
  NavItem(
    rota: '/assistente',
    label: 'Ferret Jr',
    icone: Icons.auto_awesome_outlined,
    grupo: 'ASSISTENTE',
    titulo: 'Ferret Jr',
    subtitulo: 'Assistente inteligente da operação',
    badge: 'IA',
  ),
];

const NavItem itemConfiguracoes = NavItem(
  rota: '/configuracoes',
  label: 'Configurações',
  icone: Icons.settings_outlined,
  grupo: 'ADMINISTRAÇÃO',
  titulo: 'Configurações',
  subtitulo: 'Parâmetros do sistema',
);

const double _larguraAberta = 264;
const double _larguraEncolhida = 64;
const Duration _duracaoMenu = Duration(milliseconds: 160);

final StateProvider<bool> sidebarFixaProvider =
    StateProvider<bool>((ref) => true);

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.rotaAtual});

  final Widget child;
  final String rotaAtual;

  int get _indice =>
      navItems.indexWhere((NavItem n) => rotaAtual.startsWith(n.rota));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool largo = MediaQuery.sizeOf(context).width >= 900;
    final NavItem atual = rotaAtual.startsWith(itemConfiguracoes.rota)
        ? itemConfiguracoes
        : navItems[_indice < 0 ? 0 : _indice];

    if (largo) {
      final bool fixa = ref.watch(sidebarFixaProvider);
      return Scaffold(
        body: SafeArea(
          child: Stack(
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
        actions: const <Widget>[
          _PeriodoDosDados(),
          SizedBox(width: AppSpacing.md)
        ],
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

  Widget _botaoConfiguracoes() => IconButton(
        tooltip: itemConfiguracoes.label,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.settings_outlined,
            size: 18, color: AppColors.sidebarText),
        onPressed: () => _irPara(itemConfiguracoes),
      );

  void _alternarFixa(bool fixa) {
    ref.read(sidebarFixaProvider.notifier).state = !fixa;
    if (fixa) setState(() => _mouseEmCima = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dentroDoDrawer) {
      return ColoredBox(
        color: AppColors.sidebar,
        child: SafeArea(child: _aberta(fixa: null)),
      );
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
          boxShadow: aberta && !fixa
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(2, 0),
                  ),
                ]
              : null,
        ),
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: largura,
          maxWidth: largura,
          child: aberta ? _aberta(fixa: fixa) : _encolhida(),
        ),
      ),
    );
  }

  Widget _encolhida() {
    return Column(
      children: <Widget>[
        const SizedBox(
          height: 64,
          child: Center(child: AppLogo(compacto: true)),
        ),
        const Divider(height: 1),
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
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: _botaoConfiguracoes(),
        ),
      ],
    );
  }

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
            padding: const EdgeInsets.fromLTRB(20, 18, AppSpacing.md, 6),
            child: Text(
              n.grupo,
              style: AppTextStyles.overline.copyWith(
                fontSize: 10.5,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
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
        SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md + 2,
              0,
              AppSpacing.sm,
              0,
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
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: itens,
          ),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md + 2,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: LogoScs(altura: 30),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md + 2,
            12,
            AppSpacing.sm,
            12,
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 32,
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: const Text(
                  'GS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Gestor SEMOB',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      usuario ?? 'gestor@semob.gov.br',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11.5, color: AppColors.sidebarText),
                    ),
                  ],
                ),
              ),
              _botaoConfiguracoes(),
              const _BotaoSair(),
            ],
          ),
        ),
      ],
    );
  }
}

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
    return Tooltip(
      message: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Material(
          color: selecionado ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            hoverColor: AppColors.sidebarHover,
            child: SizedBox(
              height: 38,
              child: Icon(
                item.icone,
                size: 19,
                color: selecionado ? AppColors.primary : AppColors.sidebarText,
              ),
            ),
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
    final Color cor = selecionado ? AppColors.primary : AppColors.sidebarText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: selecionado ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          hoverColor: AppColors.sidebarHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: <Widget>[
                Icon(item.icone, size: 18, color: cor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selecionado ? FontWeight.w600 : FontWeight.w400,
                      color: selecionado ? AppColors.textPrimary : cor,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item});

  final NavItem item;

  static String _capitalizar(String texto) => texto
      .split(' ')
      .map(
          (String p) => p.length <= 2 ? p : p[0] + p.substring(1).toLowerCase())
      .join(' ');

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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _capitalizar(item.grupo),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  item.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title,
                ),
              ],
            ),
          ),
          if (!compacto) const _PeriodoDosDados(),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Notificações',
            icon: const Icon(Icons.notifications_none,
                size: 21, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton(
            label: 'Exportar',
            compacto: true,
            secundario: true,
            icone: Icons.file_download_outlined,
            onPressed: () => context.go('/dados?aba=relatorios'),
          ),
        ],
      ),
    );
  }
}

class _PeriodoDosDados extends ConsumerWidget {
  const _PeriodoDosDados();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Painel? painel = ref.watch(painelProvider).valueOrNull;
    if (painel == null) return const SizedBox.shrink();
    final DateFormat dia = DateFormat('dd/MM/yyyy');
    return Tooltip(
      message:
          'Relatórios do Smart Report de ${dia.format(painel.inicio)} a ${dia.format(painel.fim)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.event_available_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Dados até ${dia.format(painel.fim)}',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
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

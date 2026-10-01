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
    label: 'MOBI AI',
    icone: Icons.auto_awesome_outlined,
    grupo: 'DADOS & IA',
    titulo: 'MOBI AI',
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
      return Scaffold(
        body: Row(
          children: <Widget>[
            _Sidebar(indice: _indice),
            Expanded(
              child: Column(
                children: <Widget>[
                  _Header(item: atual),
                  Expanded(child: child),
                ],
              ),
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

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.indice, this.dentroDoDrawer = false});

  final int indice;
  final bool dentroDoDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              n.grupo,
              style:
                  AppTextStyles.overline.copyWith(color: AppColors.sidebarText),
            ),
          ),
        );
      }
      itens.add(
        _ItemNav(
          item: n,
          selecionado: i == indice,
          onTap: () {
            if (dentroDoDrawer) Navigator.of(context).pop();
            context.go(n.rota);
          },
        ),
      );
    }

    final Widget conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: AppLogo(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: itens,
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                height: 36,
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Text(
                  'GS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
                      'Gestor SEMOB',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

    if (dentroDoDrawer) {
      return ColoredBox(color: AppColors.sidebar, child: conteudo);
    }
    return Container(width: 252, color: AppColors.sidebar, child: conteudo);
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
    final Color cor = selecionado ? Colors.white : AppColors.sidebarText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
        color: selecionado ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          // Sem o overlay explicito, o hover padrao clareia o fundo escuro.
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.isEmpty
                ? null
                : (selecionado
                    ? AppColors.sidebarActive
                    : AppColors.sidebarHover),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 11,
            ),
            child: Row(
              children: <Widget>[
                Icon(item.icone, size: 19, color: cor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selecionado ? FontWeight.w600 : FontWeight.w400,
                      color: cor,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
          Text(item.titulo, style: AppTextStyles.title),
          const SizedBox(width: AppSpacing.md),
          Container(width: 1, height: 20, color: AppColors.border),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
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

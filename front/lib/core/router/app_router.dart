import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistente/pages/assistente_page.dart';
import '../../features/configuracoes/pages/configuracoes_page.dart';
import '../../features/creditos/pages/creditos_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/demanda/pages/demanda_page.dart';
import '../../features/documentos/pages/documentos_page.dart';
import '../../features/frota/pages/frota_page.dart';
import '../../features/integracoes/pages/integracoes_page.dart';
import '../../features/login/pages/login_page.dart';
import '../../features/quilometragem/pages/quilometragem_page.dart';
import '../../features/receita/pages/receita_page.dart';
import '../../features/relatorios/pages/relatorios_page.dart';
import '../../shared/widgets/app_shell.dart';

/// Rotas do MOBI.AI. Sem guard de autenticacao: o login e apenas visual.
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          AppShell(rotaAtual: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardPage(),
        ),
        GoRoute(path: '/demanda', builder: (_, __) => const DemandaPage()),
        GoRoute(path: '/receita', builder: (_, __) => const ReceitaPage()),
        GoRoute(path: '/creditos', builder: (_, __) => const CreditosPage()),
        GoRoute(path: '/frota', builder: (_, __) => const FrotaPage()),
        GoRoute(
          path: '/quilometragem',
          builder: (_, __) => const QuilometragemPage(),
        ),
        GoRoute(path: '/documentos', builder: (_, __) => const DocumentosPage()),
        GoRoute(path: '/assistente', builder: (_, __) => const AssistentePage()),
        GoRoute(path: '/relatorios', builder: (_, __) => const RelatoriosPage()),
        GoRoute(
          path: '/integracoes',
          builder: (_, __) => const IntegracoesPage(),
        ),
        GoRoute(
          path: '/configuracoes',
          builder: (_, __) => const ConfiguracoesPage(),
        ),
      ],
    ),
  ],
);

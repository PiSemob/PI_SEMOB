import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistente/pages/assistente_page.dart';
import '../../features/configuracoes/pages/configuracoes_page.dart';
import '../../features/dados/pages/dados_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/financeiro/pages/financeiro_page.dart';
import '../../features/login/pages/login_page.dart';
import '../../features/login/pages/recuperar_senha_page.dart';
import '../../features/login/pages/redefinir_senha_page.dart';
import '../../features/operacao/pages/operacao_page.dart';
import '../../shared/widgets/app_shell.dart';

const Map<String, String> rotasAntigas = <String, String>{
  '/demanda': '/operacao?aba=demanda',
  '/frota': '/operacao?aba=frota',
  '/quilometragem': '/operacao?aba=quilometragem',
  '/creditos': '/receita?aba=creditos',
  '/documentos': '/dados?aba=documentos',
  '/integracoes': '/dados?aba=integracoes',
  '/relatorios': '/dados?aba=relatorios',
};

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: '/recuperar-senha',
      builder: (_, GoRouterState s) =>
          RecuperarSenhaPage(email: s.uri.queryParameters['email']),
    ),
    GoRoute(
      path: '/redefinir-senha',
      builder: (_, GoRouterState s) =>
          RedefinirSenhaPage(token: s.uri.queryParameters['token']),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          AppShell(rotaAtual: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardPage(),
        ),
        GoRoute(
          path: '/operacao',
          builder: (_, GoRouterState s) =>
              OperacaoPage(aba: s.uri.queryParameters['aba']),
        ),
        GoRoute(
          path: '/receita',
          builder: (_, GoRouterState s) =>
              FinanceiroPage(aba: s.uri.queryParameters['aba']),
        ),
        GoRoute(
          path: '/dados',
          builder: (_, GoRouterState s) =>
              DadosPage(aba: s.uri.queryParameters['aba']),
        ),
        GoRoute(
            path: '/assistente', builder: (_, __) => const AssistentePage()),
        GoRoute(
          path: '/configuracoes',
          builder: (_, __) => const ConfiguracoesPage(),
        ),
        for (final MapEntry<String, String> antiga in rotasAntigas.entries)
          GoRoute(path: antiga.key, redirect: (_, __) => antiga.value),
      ],
    ),
  ],
);

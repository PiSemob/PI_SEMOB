import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobi_ai/core/autenticacao/servico_autenticacao.dart';
import 'package:mobi_ai/core/autenticacao/sessao.dart';
import 'package:mobi_ai/features/login/pages/login_page.dart';

import '../apoio/api_falsa.dart';

class _ArmazenamentoFalso extends ArmazenamentoSessao {
  String? token;

  @override
  Future<String?> lerToken() async => token;

  @override
  Future<bool> guardar(String novo) async {
    token = novo;
    return true;
  }

  @override
  Future<bool> apagar() async {
    token = null;
    return true;
  }
}

void main() {
  late ServicoFalso servico;
  late _ArmazenamentoFalso armazenamento;
  late ProviderContainer container;

  Widget app() {
    servico = ServicoFalso();
    armazenamento = _ArmazenamentoFalso();
    container = ProviderContainer(overrides: <Override>[
      servicoAutenticacaoProvider.overrideWithValue(servico),
      armazenamentoSessaoProvider.overrideWithValue(armazenamento),
    ]);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: <RouteBase>[
            GoRoute(path: '/', builder: (_, __) => const LoginPage()),
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const Scaffold(body: Text('Dashboard')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('Validação de campos vazios no Login (Caixa Preta)',
      (WidgetTester tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(find.text('Mínimo de 4 caracteres'), findsOneWidget);
    expect(servico.chamadas, isEmpty);
  });

  testWidgets('Fluxo de sucesso no Login abre a sessão e guarda o token',
      (WidgetTester tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(
        find.byType(TextFormField).at(0), 'ana@semob.sp.gov.br');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha-certa');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(container.read(sessaoProvider)?.nome, 'Ana Souza');
    expect(armazenamento.token, 'tk');
  });

  testWidgets('Senha errada mostra a mensagem do back e fica no login',
      (WidgetTester tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(
        find.byType(TextFormField).at(0), 'ana@semob.sp.gov.br');
    await tester.enterText(find.byType(TextFormField).at(1), 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
        find.textContaining('E-mail ou senha incorretos.', findRichText: true),
        findsOneWidget);
    expect(container.read(sessaoProvider), isNull);
    expect(find.text('Modo demonstração.', findRichText: true), findsNothing);
  });
}

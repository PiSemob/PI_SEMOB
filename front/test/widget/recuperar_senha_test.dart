import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobi_ai/core/autenticacao/servico_autenticacao.dart';
import 'package:mobi_ai/features/login/pages/login_page.dart';
import 'package:mobi_ai/features/login/pages/recuperar_senha_page.dart';
import 'package:mobi_ai/features/login/pages/redefinir_senha_page.dart';

class _ServicoFalho implements ServicoAutenticacao {
  @override
  bool get demonstracao => false;

  @override
  Future<void> pedirRecuperacao(String email) async =>
      throw const ErroAutenticacao('Servidor indisponível.');

  @override
  Future<void> redefinirSenha(
          {required String token, required String novaSenha}) async =>
      throw const ErroAutenticacao(
          'Este link é inválido ou expirou. Peça um novo.');
}

void main() {
  setUp(() {
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(600, 1000);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding
      .instance.platformDispatcher.views.first
      .reset());

  Widget app(String inicio, {ServicoAutenticacao? servico}) {
    return ProviderScope(
      overrides: <Override>[
        servicoAutenticacaoProvider.overrideWithValue(
          servico ?? const ServicoAutenticacaoDemo(espera: Duration.zero),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: inicio,
          routes: <RouteBase>[
            GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
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
          ],
        ),
      ),
    );
  }

  testWidgets('Esqueci minha senha leva o e-mail digitado para a recuperação',
      (WidgetTester tester) async {
    await tester.pumpWidget(app('/login'));
    await tester.enterText(
        find.byType(TextFormField).first, 'gestor@semob.gov.br');
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.byType(RecuperarSenhaPage), findsOneWidget);
    final EditableText campo =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(campo.controller.text, 'gestor@semob.gov.br');
  });

  testWidgets('Recuperação valida o e-mail e confirma o envio',
      (WidgetTester tester) async {
    await tester.pumpWidget(app('/recuperar-senha'));
    await tester.tap(find.text('Enviar link'));
    await tester.pump();
    expect(find.text('Informe um e-mail válido'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'gestor@semob.gov.br');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(find.text('Confira seu e-mail'), findsOneWidget);

    await tester.tap(find.text('Abrir o link de redefinição'));
    await tester.pumpAndSettle();
    expect(find.text('Criar senha nova'), findsOneWidget);
  });

  testWidgets('Erro do back aparece na tela', (WidgetTester tester) async {
    await tester.pumpWidget(
        app('/recuperar-senha?email=a@b.com', servico: _ServicoFalho()));
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    expect(find.text('Erro. Servidor indisponível.', findRichText: true),
        findsOneWidget);
    expect(find.text('Confira seu e-mail'), findsNothing);
  });

  testWidgets('Redefinição sem código mostra link inválido',
      (WidgetTester tester) async {
    await tester.pumpWidget(app('/redefinir-senha'));
    await tester.pumpAndSettle();
    expect(find.text('Link inválido'), findsOneWidget);
  });

  testWidgets('Redefinição confere as senhas e salva',
      (WidgetTester tester) async {
    await tester.pumpWidget(app('/redefinir-senha?token=abc'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'senhaNova1');
    await tester.enterText(find.byType(TextFormField).at(1), 'outraSenha');
    await tester.tap(find.text('Salvar senha'));
    await tester.pump();
    expect(find.text('As senhas não são iguais'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'senhaNova1');
    await tester.tap(find.text('Salvar senha'));
    await tester.pumpAndSettle();
    expect(find.text('Senha alterada'), findsOneWidget);
  });
}

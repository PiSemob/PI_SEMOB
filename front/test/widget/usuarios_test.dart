import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/core/autenticacao/sessao.dart';
import 'package:mobi_ai/features/login/pages/redefinir_senha_page.dart';
import 'package:mobi_ai/features/usuarios/pages/usuarios_page.dart';
import 'package:mobi_ai/shared/painel.dart';
import 'package:mobi_ai/shared/widgets/app_shell.dart';

import '../apoio/api_falsa.dart';
import '../apoio/painel_teste.dart';

void main() {
  late ApiFalsa api;

  Widget app(Widget tela, {Sessao sessao = sessaoDeTeste}) {
    api = ApiFalsa();
    return ProviderScope(
      overrides: <Override>[
        apiClientProvider.overrideWithValue(api),
        sessaoInicialProvider.overrideWithValue(sessao),
        painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
      ],
      child: MaterialApp(home: Scaffold(body: tela)),
    );
  }

  setUp(() {
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1400, 1800);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding
      .instance.platformDispatcher.views.first
      .reset());

  testWidgets('Lista os usuários com perfil e convite pendente',
      (WidgetTester tester) async {
    await tester.pumpWidget(app(const UsuariosPage()));
    await tester.pumpAndSettle();

    expect(find.text('USUÁRIOS (2)'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Você'), findsOneWidget);
    expect(find.text('Convite pendente'), findsOneWidget);
    expect(find.byTooltip('Ações'), findsOneWidget);
  });

  testWidgets('Convite pede nome e e-mail válidos e chama a API',
      (WidgetTester tester) async {
    await tester.pumpWidget(app(const UsuariosPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe um e-mail válido'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Carla Dias');
    await tester.enterText(
        find.byType(TextField).at(1), 'carla@semob.sp.gov.br');
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();

    expect(api.pedidos,
        contains('convidar:carla@semob.sp.gov.br:Carla Dias:true'));
    expect(find.text('Convite enviado para carla@semob.sp.gov.br.'),
        findsOneWidget);
    expect(find.text('USUÁRIOS (3)'), findsOneWidget);
  });

  testWidgets('Remover acesso pede confirmação', (WidgetTester tester) async {
    await tester.pumpWidget(app(const UsuariosPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ações'));
    await tester.pumpAndSettle();
    expect(find.text('Reenviar convite'), findsOneWidget);
    await tester.tap(find.text('Remover acesso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.pedidos, isNot(contains('remover:2')));

    await tester.tap(find.byTooltip('Ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover acesso'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(api.pedidos, contains('remover:2'));
    expect(find.text('Bruno Lima'), findsNothing);
    expect(find.text('USUÁRIOS (1)'), findsOneWidget);
  });

  const Widget shell = AppShell(rotaAtual: '/dashboard', child: SizedBox());

  testWidgets('Administrador vê Usuários no menu', (WidgetTester tester) async {
    await tester.pumpWidget(app(shell));
    await tester.pumpAndSettle();
    expect(find.text('Usuários'), findsOneWidget);
  });

  testWidgets('Usuário comum não vê Usuários no menu',
      (WidgetTester tester) async {
    const Sessao comum =
        Sessao(email: 'caio@semob.sp.gov.br', nome: 'Caio', token: 'tk');
    await tester.pumpWidget(app(shell, sessao: comum));
    await tester.pumpAndSettle();
    expect(find.text('Usuários'), findsNothing);
  });

  testWidgets('Link do convite abre a tela de boas-vindas',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(app(const RedefinirSenhaPage(token: 'abc', convite: true)));
    await tester.pump();
    expect(find.text('Boas-vindas ao Ferret'), findsOneWidget);
  });

  testWidgets('Convite expirado manda falar com o administrador',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(app(const RedefinirSenhaPage(token: '', convite: true)));
    await tester.pump();
    expect(find.textContaining('Peça ao administrador'), findsOneWidget);
  });
}

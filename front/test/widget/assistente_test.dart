import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/features/assistente/pages/assistente_page.dart';
import 'package:mobi_ai/shared/painel.dart';

import '../apoio/api_falsa.dart';
import '../apoio/painel_teste.dart';

void main() {
  late ApiFalsa api;

  Widget app({Size tamanho = const Size(1300, 900)}) {
    api = ApiFalsa();
    return ProviderScope(
      overrides: <Override>[
        apiClientProvider.overrideWithValue(api),
        painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
      ],
      child: const MaterialApp(home: Scaffold(body: AssistentePage())),
    );
  }

  setUp(() {
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1300, 900);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding
      .instance.platformDispatcher.views.first
      .reset());

  testWidgets('Envia a pergunta à API e mostra a resposta com os números',
      (WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField), 'Qual linha fez mais viagens?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(api.pedidos, contains('chat:Qual linha fez mais viagens?:-'));
    expect(find.text('Qual linha fez mais viagens?'), findsWidgets);
    expect(find.text('A linha 03 foi a que mais fez viagens: 5.848.'),
        findsOneWidget);
    expect(find.text('Viagens por linha · 01/08/2026 a 31/08/2026'),
        findsOneWidget);
    expect(find.text('5.848'), findsOneWidget);
  });

  testWidgets('A segunda pergunta continua a mesma conversa',
      (WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Primeira');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'E em setembro?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(api.pedidos, contains('chat:E em setembro?:c1'));
  });

  testWidgets('Erro da API aparece no chat', (WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    api.erro = const ErroApi('Servidor fora do ar.');

    await tester.enterText(find.byType(TextField), 'Olá');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Não consegui responder agora: Servidor fora do ar.'),
        findsOneWidget);
  });

  testWidgets('Histórico vem da API e abre a conversa antiga',
      (WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Conversa de ontem'), findsOneWidget);
    await tester.tap(find.text('Conversa de ontem'));
    await tester.pumpAndSettle();

    expect(api.pedidos, contains('conversa:antiga'));
    expect(find.text('Resposta antiga'), findsOneWidget);
  });

  testWidgets('Nova conversa limpa o chat atual', (WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Olá');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova conversa'));
    await tester.pumpAndSettle();

    expect(find.text('A linha 03 foi a que mais fez viagens: 5.848.'),
        findsNothing);
    expect(find.text('Ferret Jr'), findsOneWidget); // volta para as sugestões
  });
}

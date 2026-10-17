import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobi_ai/features/assistente/pages/assistente_page.dart';

void main() {
  Widget createAssistenteWidget() {
    return ProviderScope(
      child: MaterialApp(home: AssistentePage()),
    );
  }

  testWidgets('Deve enviar mensagem e receber resposta automática', (WidgetTester tester) async {
    await tester.pumpWidget(createAssistenteWidget());

    final campoTexto = find.byType(TextField);
    final botaoEnviar = find.byIcon(Icons.send);

    await tester.enterText(campoTexto, 'Qual a demanda de hoje?');
    await tester.tap(botaoEnviar);
    await tester.pumpAndSettle();

    expect(find.text('Qual a demanda de hoje?'), findsOneWidget);
    
    expect(find.textContaining('Interface de demonstracao'), findsOneWidget);
  });

  testWidgets('Deve criar nova conversa e limpar chat atual', (WidgetTester tester) async {
    await tester.pumpWidget(createAssistenteWidget());

    await tester.enterText(find.byType(TextField), 'Olá');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    final btnNova = find.text('Nova conversa');
    await tester.tap(btnNova);
    await tester.pumpAndSettle();

    expect(find.text('Olá'), findsNothing);
    expect(find.text('Ferret Jr'), findsOneWidget); // Volta para tela de sugestões
  });
}

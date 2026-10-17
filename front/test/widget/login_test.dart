import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ferret_bi/features/login/pages/login_page.dart';

void main() {
  Widget createWidgetForTesting() {
    return ProviderScope(
      child: MaterialApp(home: LoginPage()),
    );
  }

  testWidgets('Validação de campos vazios no Login (Caixa Preta)', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetForTesting());

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Insira um e-mail válido'), findsOneWidget);
    expect(find.text('Insira a senha'), findsOneWidget);
  });

  testWidgets('Fluxo de sucesso no Login', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetForTesting());

    await tester.enterText(find.byType(TextFormField).at(0), 'teste@semob.gov.br');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
  });
}

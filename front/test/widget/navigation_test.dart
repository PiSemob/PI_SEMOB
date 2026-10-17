import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobi_ai/shared/widgets/app_shell.dart';

void main() {
  testWidgets('Teste de Responsividade da Sidebar (Regressão)', (WidgetTester tester) async {
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppShell(rotaAtual: '/dashboard', child: SizedBox()),
        ),
      ),
    );

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing); // Sidebar deve estar visível no corpo

    tester.view.physicalSize = const Size(375, 667);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsNothing);
  });
}

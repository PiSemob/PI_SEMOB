import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ferret_bi/shared/widgets/app_shell.dart';
import 'package:ferret_bi/shared/providers.dart';

void main() {
  testWidgets('Teste de Responsividade da Sidebar (Regressão)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AppShell(child: Container(), rotaAtual: '/dashboard'),
        ),
      ),
    );

    tester.view.physicalSize = Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing); // Sidebar deve estar visível no corpo

    tester.view.physicalSize = Size(375, 667);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsNothing); 
  });
}

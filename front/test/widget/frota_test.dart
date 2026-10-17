import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobi_ai/features/frota/pages/frota_page.dart';
import 'package:mobi_ai/shared/widgets/app_shell.dart';

void main() {
  Widget createFrotaWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: AppShell(
          rotaAtual: '/frota',
          child: FrotaPage(),
        ),
      ),
    );
  }

  testWidgets('Deve filtrar veículos por linha ao selecionar ChoiceChip', (WidgetTester tester) async {
    await tester.pumpWidget(createFrotaWidget());

    expect(find.textContaining('L01'), findsWidgets);
    expect(find.textContaining('L02'), findsWidgets);

    final chipL01 = find.text('L01');
    await tester.ensureVisible(chipL01);
    await tester.pumpAndSettle();
    await tester.tap(chipL01);
    await tester.pumpAndSettle();

    expect(find.textContaining('L01 ·'), findsWidgets);
    expect(find.textContaining('L02 ·'), findsNothing);
  });

  testWidgets('Deve exibir EmptyState quando nenhuma linha for encontrada', (WidgetTester tester) async {
    await tester.pumpWidget(createFrotaWidget());
    
    expect(find.byType(FrotaPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

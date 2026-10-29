import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/features/dados/widgets/fluxo_processamento.dart';

void main() {
  testWidgets(
      'FluxoProcessamento deve alternar entre Row (Desktop) e Column (Mobile)',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: FluxoProcessamento()))));

    expect(find.byIcon(Icons.arrow_forward), findsWidgets);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);

    tester.view.physicalSize = const Size(375, 667);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: FluxoProcessamento()))));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward), findsWidgets);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);

    addTearDown(tester.view.reset);
  });
}

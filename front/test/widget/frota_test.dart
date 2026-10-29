import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobi_ai/features/operacao/widgets/aba_frota.dart';
import 'package:mobi_ai/shared/painel.dart';
import 'package:mobi_ai/shared/widgets/app_widgets.dart';

import '../apoio/painel_teste.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Future<void> abrirFrota(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
        ],
        child: const MaterialApp(home: Scaffold(body: AbaFrota())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> escolherLinha(WidgetTester tester, String codigo) async {
    final Finder tag = find.widgetWithText(TagFiltro, codigo);
    await tester.ensureVisible(tag);
    await tester.tap(tag);
    await tester.pumpAndSettle();
  }

  testWidgets('Deve filtrar as viagens com problema pela linha escolhida',
      (WidgetTester tester) async {
    await abrirFrota(tester);

    expect(find.text('ATENDIMENTO DA 01'), findsOneWidget);
    expect(find.text('ATENDIMENTO DA 02'), findsOneWidget);

    await escolherLinha(tester, '01');

    expect(find.text('ATENDIMENTO DA 01'), findsOneWidget);
    expect(find.text('ATENDIMENTO DA 02'), findsNothing);
  });

  testWidgets(
      'Deve exibir EmptyState quando a linha não tem viagens com problema',
      (WidgetTester tester) async {
    await abrirFrota(tester);

    await escolherLinha(tester, '03');

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('ATENDIMENTO DA 01'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

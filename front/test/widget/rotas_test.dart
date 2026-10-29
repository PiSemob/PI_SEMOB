import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobi_ai/core/router/app_router.dart';
import 'package:mobi_ai/shared/painel.dart';

import '../apoio/painel_teste.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('Endereços das telas antigas abrem a aba certa da tela nova',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );

    for (final MapEntry<String, String> rota in rotasAntigas.entries) {
      appRouter.go(rota.key);
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.toString(),
        rota.value,
        reason: '${rota.key} deveria levar a ${rota.value}',
      );
    }
    expect(tester.takeException(), isNull);
  });

  test('Toda rota antiga aponta para uma aba de uma tela que existe', () {
    final Set<String> telas = <String>{'/operacao', '/receita', '/dados'};
    for (final String destino in rotasAntigas.values) {
      final Uri uri = Uri.parse(destino);
      expect(telas, contains(uri.path));
      expect(uri.queryParameters['aba'], isNotEmpty);
    }
    expect(GoRouter, isNotNull);
  });
}

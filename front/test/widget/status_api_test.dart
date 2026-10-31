import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/shared/widgets/app_shell.dart';

class _ApiFalsa extends ApiClient {
  _ApiFalsa(this.respostas);

  final List<bool> respostas;
  int chamadas = 0;

  @override
  Future<bool> estaNoAr() async => respostas[chamadas++];
}

Future<void> _montar(WidgetTester tester, _ApiFalsa api) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[apiClientProvider.overrideWithValue(api)],
      child: const MaterialApp(
        home: AppShell(rotaAtual: '/dashboard', child: SizedBox()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cabeçalho mostra que a API está no ar',
      (WidgetTester tester) async {
    await _montar(tester, _ApiFalsa(<bool>[true]));
    expect(find.text('API no ar'), findsOneWidget);
  });

  testWidgets('API fora do ar pode ser verificada de novo com um toque',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa(<bool>[false, true]);
    await _montar(tester, api);
    expect(find.text('API fora do ar'), findsOneWidget);

    await tester.tap(find.text('API fora do ar'));
    await tester.pumpAndSettle();

    expect(api.chamadas, 2);
    expect(find.text('API no ar'), findsOneWidget);
  });
}

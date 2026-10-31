import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/features/operacao/widgets/aba_quilometragem.dart';
import 'package:mobi_ai/shared/painel.dart';
import 'package:mobi_ai/shared/providers.dart';

import '../apoio/painel_teste.dart';

class _ApiFalsa extends ApiClient {
  final List<(String, String?)> pedidos = <(String, String?)>[];

  @override
  Future<Map<String, dynamic>> previsao({
    required String alvo,
    String? linha,
    int dias = 7,
  }) async {
    pedidos.add((alvo, linha));
    final double valor = alvo == 'km' ? 6800 : 1100;
    return <String, dynamic>{
      'serie': alvo,
      'linha': linha,
      'modelo': 'sarimax',
      'erro_na_validacao': <String, dynamic>{'mae': 18.6, 'mape': 2.5},
      'previsao': <Map<String, dynamic>>[
        <String, dynamic>{
          'data': '2026-09-15',
          'previsto': valor,
          'minimo': valor - 50,
          'maximo': valor + 50,
        },
      ],
    };
  }
}

Future<ProviderContainer> _montar(WidgetTester tester, _ApiFalsa api) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1.0;
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
      apiClientProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: AbaQuilometragem())),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('sem linha escolhida, prevê viagens e km do sistema',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa();
    await _montar(tester, api);

    expect(api.pedidos,
        unorderedEquals(<(String, String?)>[('viagens', null), ('km', null)]));
    expect(find.text('Previsão de viagens do sistema'), findsOneWidget);
    expect(find.text('Previsão de km do sistema'), findsOneWidget);
    expect(find.text('6.800 km'), findsOneWidget);
  });

  testWidgets('com uma linha escolhida, a previsão passa a ser da linha',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa();
    final ProviderContainer container = await _montar(tester, api);

    container.read(linhaSelecionadaProvider.notifier).selecionar('02');
    await tester.pumpAndSettle();

    expect(api.pedidos,
        containsAll(<(String, String?)>[('viagens', '02'), ('km', '02')]));
    expect(find.text('Previsão de viagens da linha 02'), findsOneWidget);
    expect(find.text('Previsão de km da linha 02'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/features/operacao/widgets/aba_demanda.dart';
import 'package:mobi_ai/shared/painel.dart';

import '../apoio/painel_teste.dart';

class _ApiFalsa extends ApiClient {
  _ApiFalsa({this.erro});

  final ErroApi? erro;
  final List<(String, String?)> pedidos = <(String, String?)>[];

  @override
  Future<Map<String, dynamic>> previsao({
    required String alvo,
    String? linha,
    int dias = 7,
  }) async {
    pedidos.add((alvo, linha));
    if (erro != null) throw erro!;
    return <String, dynamic>{
      'serie': alvo,
      'linha': linha,
      'modelo': 'prophet',
      'erro_na_validacao': <String, dynamic>{'mae': 3150.0, 'mape': 13.8},
      'previsao': <Map<String, dynamic>>[
        <String, dynamic>{
          'data': '2026-09-15',
          'previsto': 36200.0,
          'minimo': 31000.0,
          'maximo': 41000.0,
        },
        <String, dynamic>{
          'data': '2026-09-16',
          'previsto': 35800.0,
          'minimo': 30500.0,
          'maximo': 40900.0,
        },
      ],
    };
  }
}

Future<void> _montar(WidgetTester tester, _ApiFalsa api) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
        apiClientProvider.overrideWithValue(api),
      ],
      child: const MaterialApp(home: Scaffold(body: AbaDemanda())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aba de demanda mostra a previsão de passageiros do sistema',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa();
    await _montar(tester, api);

    expect(api.pedidos, <(String, String?)>[('passageiros', null)]);
    expect(find.text('Previsão de passageiros'), findsOneWidget);
    expect(find.textContaining('modelo Prophet'), findsOneWidget);
    expect(find.textContaining('13,8%'), findsOneWidget);
    expect(find.text('36.200'), findsOneWidget);
    expect(find.text('31.000 a 41.000'), findsOneWidget);
  });

  testWidgets('erro da API aparece no cartão e pode ser tentado de novo',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa(
        erro:
            const ErroApi('Não consegui falar com o servidor. Tente de novo.'));
    await _montar(tester, api);

    expect(find.textContaining('Previsão indisponível'), findsOneWidget);
    expect(find.textContaining('Não consegui falar com o servidor'),
        findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(api.pedidos.length, 2);
  });
}

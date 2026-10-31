import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/features/operacao/widgets/aba_frota.dart';
import 'package:mobi_ai/shared/anomalias.dart';
import 'package:mobi_ai/shared/painel.dart';
import 'package:mobi_ai/shared/providers.dart';

import '../apoio/painel_teste.dart';

class _ApiFalsa extends ApiClient {
  _ApiFalsa({this.erro});

  final ErroApi? erro;
  final List<(String, DateTime, DateTime, String?)> pedidos =
      <(String, DateTime, DateTime, String?)>[];

  @override
  Future<bool> estaNoAr() async => true;

  @override
  Future<Map<String, dynamic>> anomalias({
    required String modelo,
    required DateTime inicio,
    required DateTime fim,
    String? linha,
  }) async {
    pedidos.add((modelo, inicio, fim, linha));
    if (erro != null) throw erro!;
    if (modelo == 'isolation_forest') {
      return <String, dynamic>{
        'anomalias': <Map<String, dynamic>>[
          <String, dynamic>{
            'data': '2026-09-14',
            'linha': '01',
            'pontuacao': 0.705,
            'destaque': 'nr_viagens: 4.5 desvios abaixo do normal',
          },
          <String, dynamic>{
            'data': '2026-07-09',
            'linha': '02',
            'pontuacao': 0.69,
            'destaque': 'km_total: 3.1 desvios abaixo do normal',
          },
        ],
      };
    }
    return <String, dynamic>{
      'anomalias': <Map<String, dynamic>>[
        <String, dynamic>{
          'inicio_realizado': '2026-09-14T18:44:26',
          'sentido': 'I',
          'prefixo': '1502',
          'duracao_min': 23.6,
          'km_total': 6.8,
          'mediana_duracao': 31.0,
          'mediana_km': 8.9,
        },
      ],
    };
  }
}

Future<ProviderContainer> _montar(WidgetTester tester, _ApiFalsa api) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(1400, 4000);
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
      child: const MaterialApp(home: Scaffold(body: AbaFrota())),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('destaque do modelo vira texto em português', () {
    final DiaAtipico dia = DiaAtipico(
      data: DateTime(2026, 9, 7),
      linha: '07',
      pontuacao: 0.7,
      destaque: 'km_por_viagem: 4.5 desvios acima do normal',
    );
    expect(dia.explicacao, 'Km por viagem: 4,5 desvios acima do normal');
  });

  testWidgets('pede os dias atípicos da base inteira e mostra os do período',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa();
    await _montar(tester, api);

    expect(api.pedidos, <(String, DateTime, DateTime, String?)>[
      ('isolation_forest', DateTime(2026, 9, 13), DateTime(2026, 9, 14), null),
    ]);
    expect(find.text('Dias atípicos'), findsOneWidget);
    expect(find.text('Viagens: 4,5 desvios abaixo do normal'), findsOneWidget);
    expect(find.text('Km: 3,1 desvios abaixo do normal'), findsNothing);
    expect(find.textContaining('Viagens atípicas da linha'), findsNothing);
  });

  testWidgets('com uma linha escolhida, mostra também as viagens atípicas',
      (WidgetTester tester) async {
    final _ApiFalsa api = _ApiFalsa();
    final ProviderContainer container = await _montar(tester, api);

    container.read(linhaSelecionadaProvider.notifier).selecionar('01');
    await tester.pumpAndSettle();

    expect(api.pedidos.last,
        ('dbscan', DateTime(2026, 9, 13), DateTime(2026, 9, 14), '01'));
    expect(find.text('Viagens atípicas da linha 01'), findsOneWidget);
    expect(find.text('14/09 18:44'), findsOneWidget);
    expect(find.text('23,6 (normal 31,0)'), findsOneWidget);
  });

  testWidgets('erro da API aparece no cartão sem derrubar a aba',
      (WidgetTester tester) async {
    await _montar(
        tester,
        _ApiFalsa(
            erro: const ErroApi('Nenhuma linha com pelo menos 30 dias.')));

    expect(find.textContaining('Anomalias indisponíveis'), findsOneWidget);
    expect(find.textContaining('30 dias'), findsOneWidget);
    expect(find.text('Viagens com problema'), findsWidgets);
  });
}

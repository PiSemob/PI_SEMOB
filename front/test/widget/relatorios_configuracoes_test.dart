import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/core/autenticacao/sessao.dart';
import 'package:mobi_ai/core/download/salvar_arquivo.dart';
import 'package:mobi_ai/features/configuracoes/pages/configuracoes_page.dart';
import 'package:mobi_ai/features/relatorios/pages/relatorios_page.dart';
import 'package:mobi_ai/shared/painel.dart';
import 'package:mobi_ai/shared/widgets/sino_notificacoes.dart';

import '../apoio/api_falsa.dart';
import '../apoio/painel_teste.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  late ApiFalsa api;

  Widget app(Widget tela) {
    api = ApiFalsa();
    return ProviderScope(
      overrides: <Override>[
        apiClientProvider.overrideWithValue(api),
        painelProvider.overrideWith((Ref ref) async => painelDeTeste()),
        sessaoInicialProvider.overrideWithValue(sessaoDeTeste),
        salvarArquivoProvider.overrideWithValue(
            (String nome, String tipo, _) async => 'Download iniciado: $nome'),
      ],
      child: MaterialApp(home: Scaffold(body: tela)),
    );
  }

  setUp(() {
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1400, 2600);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding
      .instance.platformDispatcher.views.first
      .reset());

  testWidgets('Gerar relatório chama a API e mostra o relatório',
      (WidgetTester tester) async {
    await tester.pumpWidget(app(const RelatoriosPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gerar relatório'));
    await tester.pumpAndSettle();

    expect(api.pedidos, contains('gerar:executivo'));
    expect(
        find.text('Em agosto, o cumprimento foi de 99,84%.'), findsOneWidget);
    expect(find.text('Visão geral da operação'), findsOneWidget);
  });

  testWidgets('Exportar usa o relatório já gerado',
      (WidgetTester tester) async {
    await tester.pumpWidget(app(const RelatoriosPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar relatório'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();

    expect(api.pedidos, contains('exportar:xlsx:gerado'));
    expect(find.text('Download iniciado: relatorio.xlsx'), findsOneWidget);
  });

  testWidgets('Configurações carregam da API e salvam as mudanças',
      (WidgetTester tester) async {
    await tester.pumpWidget(app(const ConfiguracoesPage()));
    await tester.pumpAndSettle();

    expect(find.text('Mapa — HERE Maps API'), findsNothing);
    expect(find.text('Intervalo de atualização'), findsNothing);
    await tester.enterText(find.byType(TextField).at(1), 'Santo André');
    await tester.tap(find.byType(Switch).first);
    await tester.tap(find.text('Salvar configurações'));
    await tester.pumpAndSettle();

    expect(api.ultimoSalvo?['cidade'], 'Santo André');
    expect(api.ultimoSalvo?['alertas_anomalia'], isFalse);
    expect(api.ultimoSalvo?.keys, isNot(contains('here_api_key')));
    expect(find.text('Configurações salvas.'), findsOneWidget);
  });

  testWidgets('Sino mostra o número de avisos e a lista',
      (WidgetTester tester) async {
    await tester.pumpWidget(app(const Center(child: SinoNotificacoes())));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byType(SinoNotificacoes));
    await tester.pumpAndSettle();

    expect(find.text('Linha 08 fora do padrão em 11/09/2026'), findsOneWidget);
  });
}

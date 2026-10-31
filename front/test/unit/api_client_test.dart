import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/api/api_client.dart';

class _ServidorFalso implements HttpClientAdapter {
  _ServidorFalso(this.responder);

  final (int, Object?) Function(RequestOptions pedido) responder;
  final List<RequestOptions> pedidos = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    pedidos.add(options);
    final (int status, Object? corpo) = responder(options);
    if (corpo is Exception) throw corpo;
    return ResponseBody.fromString(
      jsonEncode(corpo),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(ApiClient, _ServidorFalso) _cliente(
    (int, Object?) Function(RequestOptions pedido) responder) {
  final _ServidorFalso servidor = _ServidorFalso(responder);
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://api.teste'))
    ..httpClientAdapter = servidor;
  return (ApiClient(dio: dio), servidor);
}

void main() {
  test('data vai no formato da API', () {
    expect(dataParaApi(DateTime(2026, 8, 1)), '2026-08-01');
    expect(dataParaApi(DateTime(2026, 12, 25)), '2026-12-25');
  });

  test('previsão manda os parâmetros e devolve o JSON', () async {
    final (ApiClient api, _ServidorFalso servidor) = _cliente(
      (_) => (
        200,
        <String, dynamic>{'modelo': 'sarimax', 'previsao': <dynamic>[]}
      ),
    );

    final Map<String, dynamic> corpo =
        await api.previsao(alvo: 'viagens', linha: '04', dias: 3);

    expect(corpo['modelo'], 'sarimax');
    expect(servidor.pedidos.single.path, '/previsoes');
    expect(servidor.pedidos.single.queryParameters,
        <String, dynamic>{'alvo': 'viagens', 'dias': 3, 'linha': '04'});
  });

  test('previsão sem linha não manda o parâmetro linha', () async {
    final (ApiClient api, _ServidorFalso servidor) =
        _cliente((_) => (200, <String, dynamic>{}));

    await api.previsao(alvo: 'passageiros');

    expect(
        servidor.pedidos.single.queryParameters.containsKey('linha'), isFalse);
    expect(servidor.pedidos.single.queryParameters['dias'], 7);
  });

  test('anomalias manda o período como texto', () async {
    final (ApiClient api, _ServidorFalso servidor) =
        _cliente((_) => (200, <String, dynamic>{'quantidade': 0}));

    await api.anomalias(
      modelo: 'isolation_forest',
      inicio: DateTime(2026, 8, 1),
      fim: DateTime(2026, 8, 31),
    );

    expect(servidor.pedidos.single.queryParameters, <String, dynamic>{
      'modelo': 'isolation_forest',
      'inicio': '2026-08-01',
      'fim': '2026-08-31',
    });
  });

  test('erro 400 vira ErroApi com a mensagem da API', () async {
    final (ApiClient api, _) = _cliente((_) => (
          400,
          <String, dynamic>{
            'detail':
                'A base só tem passageiros do sistema inteiro, não por linha.'
          }
        ));

    await expectLater(
      api.previsao(alvo: 'passageiros', linha: '04'),
      throwsA(isA<ErroApi>().having(
          (ErroApi e) => e.mensagem, 'mensagem', contains('por linha'))),
    );
  });

  test('servidor fora do ar vira mensagem amigável', () async {
    final (ApiClient api, _) = _cliente((RequestOptions pedido) => (
          0,
          DioException.connectionError(
              requestOptions: pedido, reason: 'recusada'),
        ));

    await expectLater(
      api.previsao(alvo: 'km'),
      throwsA(isA<ErroApi>().having((ErroApi e) => e.mensagem, 'mensagem',
          contains('Não consegui falar com o servidor'))),
    );
  });

  test('estaNoAr diz se a API responde, sem lançar erro', () async {
    final (ApiClient noAr, _) =
        _cliente((_) => (200, <String, dynamic>{'status': 'ok'}));
    final (ApiClient fora, _) = _cliente((RequestOptions pedido) => (
          0,
          DioException.connectionError(
              requestOptions: pedido, reason: 'recusada'),
        ));

    expect(await noAr.estaNoAr(), isTrue);
    expect(await fora.estaNoAr(), isFalse);
  });
}

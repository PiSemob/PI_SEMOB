import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Endereço da API. Entra na execução com --dart-define=API_URL=...
const String apiUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

/// Data no formato que a API espera: 2026-08-01.
String dataParaApi(DateTime data) {
  final String mes = data.month.toString().padLeft(2, '0');
  final String dia = data.day.toString().padLeft(2, '0');
  return '${data.year}-$mes-$dia';
}

/// Erro com a mensagem que a API mandou, pronta para mostrar na tela.
class ErroApi implements Exception {
  const ErroApi(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: apiUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final Dio _dio;

  Future<dynamic> _get(String rota, [Map<String, dynamic>? parametros]) async {
    try {
      final Response<dynamic> resposta =
          await _dio.get<dynamic>(rota, queryParameters: parametros);
      return resposta.data;
    } on DioException catch (erro) {
      final dynamic corpo = erro.response?.data;
      if (corpo is Map<String, dynamic> && corpo['detail'] is String) {
        throw ErroApi(corpo['detail'] as String);
      }
      throw const ErroApi('Não consegui falar com o servidor. Tente de novo.');
    }
  }

  /// Verdadeiro quando a API responde. Nunca lança erro.
  Future<bool> estaNoAr() async {
    try {
      final dynamic corpo = await _get('/saude');
      return corpo is Map<String, dynamic> && corpo['status'] == 'ok';
    } on ErroApi {
      return false;
    }
  }

  Future<Map<String, dynamic>> anomalias({
    required String modelo,
    required DateTime inicio,
    required DateTime fim,
    String? linha,
  }) async =>
      await _get('/anomalias', <String, dynamic>{
        'modelo': modelo,
        'inicio': dataParaApi(inicio),
        'fim': dataParaApi(fim),
        if (linha != null) 'linha': linha,
      }) as Map<String, dynamic>;

  Future<Map<String, dynamic>> previsao({
    required String alvo,
    String? linha,
    int dias = 7,
  }) async =>
      await _get('/previsoes', <String, dynamic>{
        'alvo': alvo,
        'dias': dias,
        if (linha != null) 'linha': linha,
      }) as Map<String, dynamic>;
}

/// As telas pegam o cliente por aqui, e os testes podem trocá-lo.
final Provider<ApiClient> apiClientProvider =
    Provider<ApiClient>((Ref ref) => ApiClient());

/// Verdadeiro quando a API respondeu. Para perguntar de novo, invalide o provider.
final FutureProvider<bool> apiNoArProvider =
    FutureProvider<bool>((Ref ref) => ref.watch(apiClientProvider).estaNoAr());

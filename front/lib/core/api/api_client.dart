import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../autenticacao/sessao.dart';

/// Endereço da API. Entra na execução com --dart-define=API_URL=...
const String apiUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

String dataParaApi(DateTime data) {
  final String mes = data.month.toString().padLeft(2, '0');
  final String dia = data.day.toString().padLeft(2, '0');
  return '${data.year}-$mes-$dia';
}

/// Erro com a mensagem que a API mandou, pronta para mostrar na tela.
class ErroApi implements Exception {
  const ErroApi(this.mensagem, {this.status});

  final String mensagem;
  final int? status;

  bool get naoAutorizado => status == 401;

  @override
  String toString() => mensagem;
}

class ArquivoBaixado {
  const ArquivoBaixado(
      {required this.nome, required this.tipo, required this.bytes});

  final String nome;
  final String tipo;
  final Uint8List bytes;
}

class ApiClient {
  ApiClient({Dio? dio, this.token, this.aoExpirar})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: apiUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 120),
              ),
            );

  final Dio _dio;

  final String? Function()? token;

  final void Function()? aoExpirar;

  Options _opcoes({ResponseType? tipo}) {
    final String? atual = token?.call();
    return Options(
      responseType: tipo,
      headers: <String, dynamic>{
        if (atual != null) 'Authorization': 'Bearer $atual',
      },
    );
  }

  Future<dynamic> _pedir(
    String metodo,
    String rota, {
    Map<String, dynamic>? parametros,
    Object? corpo,
    ResponseType? tipo,
  }) async {
    try {
      final Response<dynamic> resposta = await _dio.request<dynamic>(
        rota,
        data: corpo,
        queryParameters: parametros,
        options: _opcoes(tipo: tipo).copyWith(method: metodo),
      );
      return tipo == ResponseType.bytes ? resposta : resposta.data;
    } on DioException catch (erro) {
      final int? status = erro.response?.statusCode;
      if (status == 401 && token?.call() != null) aoExpirar?.call();
      dynamic corpoErro = erro.response?.data;
      if (corpoErro is List<int>) {
        corpoErro = null;
      }
      if (corpoErro is Map<String, dynamic> && corpoErro['detail'] is String) {
        throw ErroApi(corpoErro['detail'] as String, status: status);
      }
      if (status != null && status >= 500) {
        throw ErroApi('O servidor teve um problema. Tente de novo.',
            status: status);
      }
      throw ErroApi('Não consegui falar com o servidor. Tente de novo.',
          status: status);
    }
  }

  Future<dynamic> _get(String rota, [Map<String, dynamic>? parametros]) =>
      _pedir('GET', rota, parametros: parametros);

  Future<dynamic> _post(String rota, [Object? corpo]) =>
      _pedir('POST', rota, corpo: corpo);

  /// Verdadeiro quando a API responde. Nunca lança erro.
  Future<bool> estaNoAr() async {
    try {
      final dynamic corpo = await _get('/saude');
      return corpo is Map<String, dynamic> && corpo['status'] == 'ok';
    } on ErroApi {
      return false;
    }
  }

  Future<Sessao> entrar(String email, String senha) async {
    final Map<String, dynamic> corpo = await _post(
            '/auth/login', <String, dynamic>{'email': email, 'senha': senha})
        as Map<String, dynamic>;
    return Sessao.daApi(
        corpo['usuario'] as Map<String, dynamic>, corpo['token'] as String);
  }

  Future<Map<String, dynamic>> eu(String tokenGuardado) async {
    try {
      final Response<dynamic> resposta = await _dio.get<dynamic>(
        '/auth/eu',
        options: Options(headers: <String, dynamic>{
          'Authorization': 'Bearer $tokenGuardado'
        }),
      );
      return resposta.data as Map<String, dynamic>;
    } on DioException catch (erro) {
      throw ErroApi('Sessão inválida.', status: erro.response?.statusCode);
    }
  }

  Future<bool> sair() async {
    try {
      await _post('/auth/sair');
      return true;
    } on ErroApi {
      return false;
    }
  }

  Future<void> pedirRecuperacao(String email) =>
      _post('/auth/recuperar-senha', <String, dynamic>{'email': email});

  Future<void> redefinirSenha(String tokenDoLink, String senha) => _post(
      '/auth/redefinir-senha',
      <String, dynamic>{'token': tokenDoLink, 'senha': senha});

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

  Future<Map<String, dynamic>> conversar(String mensagem,
          {String? conversaId}) async =>
      await _post('/chat', <String, dynamic>{
        'mensagem': mensagem,
        if (conversaId != null) 'conversa_id': conversaId,
      }) as Map<String, dynamic>;

  Future<List<dynamic>> conversas() async =>
      await _get('/chat/conversas') as List<dynamic>;

  Future<Map<String, dynamic>> conversa(String id) async =>
      await _get('/chat/conversas/$id') as Map<String, dynamic>;

  Future<void> apagarConversa(String id) =>
      _pedir('DELETE', '/chat/conversas/$id');

  Future<Map<String, dynamic>> gerarRelatorio({
    required String modelo,
    required DateTime inicio,
    required DateTime fim,
  }) async =>
      await _post('/relatorios/gerar', <String, dynamic>{
        'modelo': modelo,
        'inicio': dataParaApi(inicio),
        'fim': dataParaApi(fim),
      }) as Map<String, dynamic>;

  Future<ArquivoBaixado> exportarRelatorio({
    required String modelo,
    required DateTime inicio,
    required DateTime fim,
    required String formato,
    Map<String, dynamic>? relatorio,
  }) async {
    final Response<dynamic> resposta = await _pedir(
      'POST',
      '/relatorios/exportar',
      corpo: <String, dynamic>{
        'modelo': modelo,
        'inicio': dataParaApi(inicio),
        'fim': dataParaApi(fim),
        'formato': formato,
        if (relatorio != null) 'relatorio': relatorio,
      },
      tipo: ResponseType.bytes,
    ) as Response<dynamic>;
    final String disposicao =
        resposta.headers.value('content-disposition') ?? '';
    final RegExpMatch? nome =
        RegExp(r'filename="([^"]+)"').firstMatch(disposicao);
    return ArquivoBaixado(
      nome: nome?.group(1) ?? 'relatorio.$formato',
      tipo:
          resposta.headers.value('content-type') ?? 'application/octet-stream',
      bytes: Uint8List.fromList(resposta.data as List<int>),
    );
  }

  Future<Map<String, dynamic>> configuracoes() async =>
      await _get('/configuracoes') as Map<String, dynamic>;

  Future<Map<String, dynamic>> salvarConfiguracoes(
          Map<String, dynamic> mudancas) async =>
      await _pedir('PUT', '/configuracoes', corpo: mudancas)
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> notificacoes() async =>
      await _get('/notificacoes') as Map<String, dynamic>;

  Future<List<dynamic>> usuarios() async =>
      await _get('/usuarios') as List<dynamic>;

  Future<void> convidarUsuario(
          {required String email, required String nome, required bool admin}) =>
      _post('/usuarios',
          <String, dynamic>{'email': email, 'nome': nome, 'admin': admin});

  Future<void> reenviarConvite(int id) => _post('/usuarios/$id/convite');

  Future<void> definirAdministrador(int id, {required bool admin}) =>
      _pedir('PUT', '/usuarios/$id', corpo: <String, dynamic>{'admin': admin});

  Future<void> removerUsuario(int id) => _pedir('DELETE', '/usuarios/$id');
}

/// As telas pegam o cliente por aqui, e os testes podem trocá-lo.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (Ref ref) => ApiClient(
    token: () => ref.read(sessaoProvider)?.token,
    aoExpirar: () => ref.read(sessaoProvider.notifier).expirou(),
  ),
);

/// Verdadeiro quando a API respondeu. Para perguntar de novo, invalide o provider.
final FutureProvider<bool> apiNoArProvider =
    FutureProvider<bool>((Ref ref) => ref.watch(apiClientProvider).estaNoAr());

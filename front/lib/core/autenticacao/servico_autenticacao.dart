import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'sessao.dart';

const bool modoDemo = bool.fromEnvironment('MODO_DEMO');

class ErroAutenticacao implements Exception {
  const ErroAutenticacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

abstract class ServicoAutenticacao {
  bool get demonstracao;

  Future<Sessao> entrar(String email, String senha);

  Future<void> sair();

  Future<void> pedirRecuperacao(String email);

  Future<void> redefinirSenha(
      {required String token, required String novaSenha});
}

class ServicoAutenticacaoApi implements ServicoAutenticacao {
  const ServicoAutenticacaoApi(this._api);

  final ApiClient _api;

  @override
  bool get demonstracao => false;

  Future<T> _traduzir<T>(Future<T> Function() pedido) async {
    try {
      return await pedido();
    } on ErroApi catch (erro) {
      throw ErroAutenticacao(erro.mensagem);
    }
  }

  @override
  Future<Sessao> entrar(String email, String senha) =>
      _traduzir(() => _api.entrar(email, senha));

  @override
  Future<void> sair() => _api.sair();

  @override
  Future<void> pedirRecuperacao(String email) =>
      _traduzir(() => _api.pedirRecuperacao(email));

  @override
  Future<void> redefinirSenha(
          {required String token, required String novaSenha}) =>
      _traduzir(() => _api.redefinirSenha(token, novaSenha));
}

class ServicoAutenticacaoDemo implements ServicoAutenticacao {
  const ServicoAutenticacaoDemo(
      {this.espera = const Duration(milliseconds: 600)});

  static const String tokenDemo = 'demonstracao';

  final Duration espera;

  @override
  bool get demonstracao => true;

  @override
  Future<Sessao> entrar(String email, String senha) async {
    await Future<void>.delayed(espera);
    return Sessao(
        email: email, nome: 'Gestor SEMOB', token: tokenDemo, admin: true);
  }

  @override
  Future<void> sair() async {}

  @override
  Future<void> pedirRecuperacao(String email) => Future<void>.delayed(espera);

  @override
  Future<void> redefinirSenha(
      {required String token, required String novaSenha}) async {
    await Future<void>.delayed(espera);
    if (token.isEmpty) {
      throw const ErroAutenticacao(
          'Este link é inválido ou expirou. Peça um novo.');
    }
  }
}

final Provider<ServicoAutenticacao> servicoAutenticacaoProvider =
    Provider<ServicoAutenticacao>(
  (Ref ref) => modoDemo
      ? const ServicoAutenticacaoDemo()
      : ServicoAutenticacaoApi(ref.watch(apiClientProvider)),
);

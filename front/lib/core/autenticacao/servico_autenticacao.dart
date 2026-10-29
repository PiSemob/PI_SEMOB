import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErroAutenticacao implements Exception {
  const ErroAutenticacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

abstract class ServicoAutenticacao {
  bool get demonstracao;

  Future<void> pedirRecuperacao(String email);

  Future<void> redefinirSenha(
      {required String token, required String novaSenha});
}

class ServicoAutenticacaoDemo implements ServicoAutenticacao {
  const ServicoAutenticacaoDemo(
      {this.espera = const Duration(milliseconds: 600)});

  static const String tokenDemo = 'demonstracao';

  final Duration espera;

  @override
  bool get demonstracao => true;

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
    Provider<ServicoAutenticacao>((Ref ref) => const ServicoAutenticacaoDemo());

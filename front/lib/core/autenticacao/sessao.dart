import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class Sessao {
  const Sessao({
    required this.email,
    required this.nome,
    required this.token,
    this.admin = false,
  });

  factory Sessao.daApi(Map<String, dynamic> usuario, String token) => Sessao(
        email: usuario['email'] as String,
        nome: usuario['nome'] as String,
        token: token,
        admin: usuario['admin'] == true,
      );

  final String email;
  final String nome;
  final String token;
  final bool admin;

  String get iniciais {
    final List<String> partes =
        nome.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    final String primeira = partes.first[0];
    final String ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }
}

class ArmazenamentoSessao {
  const ArmazenamentoSessao();

  static const String _chaveToken = 'ferret.token';

  Future<String?> lerToken() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_chaveToken);
    } catch (_) {
      return null;
    }
  }

  Future<bool> guardar(String token) async {
    try {
      return await (await SharedPreferences.getInstance())
          .setString(_chaveToken, token);
    } catch (_) {
      return false;
    }
  }

  Future<bool> apagar() async {
    try {
      return await (await SharedPreferences.getInstance()).remove(_chaveToken);
    } catch (_) {
      return false;
    }
  }
}

final Provider<ArmazenamentoSessao> armazenamentoSessaoProvider =
    Provider<ArmazenamentoSessao>((Ref ref) => const ArmazenamentoSessao());

final Provider<Sessao?> sessaoInicialProvider =
    Provider<Sessao?>((Ref ref) => null);

class SessaoNotifier extends Notifier<Sessao?> {
  bool expirada = false;

  @override
  Sessao? build() => ref.read(sessaoInicialProvider);

  void entrar(Sessao sessao) {
    expirada = false;
    state = sessao;
    ref.read(armazenamentoSessaoProvider).guardar(sessao.token);
  }

  void sair() {
    expirada = false;
    state = null;
    ref.read(armazenamentoSessaoProvider).apagar();
  }

  void expirou() {
    if (state == null) return;
    expirada = true;
    state = null;
    ref.read(armazenamentoSessaoProvider).apagar();
  }
}

final NotifierProvider<SessaoNotifier, Sessao?> sessaoProvider =
    NotifierProvider<SessaoNotifier, Sessao?>(SessaoNotifier.new);

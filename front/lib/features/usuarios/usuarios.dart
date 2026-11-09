import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

@immutable
class UsuarioCadastrado {
  const UsuarioCadastrado({
    required this.id,
    required this.email,
    required this.nome,
    required this.admin,
    required this.pendente,
  });

  factory UsuarioCadastrado.deJson(Map<String, dynamic> j) => UsuarioCadastrado(
        id: j['id'] as int,
        email: j['email'] as String,
        nome: j['nome'] as String,
        admin: j['admin'] as bool,
        pendente: j['pendente'] as bool,
      );

  final int id;
  final String email;
  final String nome;
  final bool admin;
  final bool pendente;
}

final AutoDisposeFutureProvider<List<UsuarioCadastrado>> usuariosProvider =
    FutureProvider.autoDispose<List<UsuarioCadastrado>>((Ref ref) async {
  final List<dynamic> lista = await ref.watch(apiClientProvider).usuarios();
  return lista
      .map((dynamic u) => UsuarioCadastrado.deJson(u as Map<String, dynamic>))
      .toList();
});

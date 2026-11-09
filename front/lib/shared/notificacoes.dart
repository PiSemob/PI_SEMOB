import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/autenticacao/sessao.dart';

@immutable
class Notificacao {
  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.texto,
    required this.data,
    required this.rota,
  });

  factory Notificacao.deJson(Map<String, dynamic> j) => Notificacao(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        titulo: j['titulo'] as String,
        texto: j['texto'] as String,
        data: DateTime.parse(j['data'] as String),
        rota: j['rota'] as String,
      );

  final String id;
  final String tipo;
  final String titulo;
  final String texto;
  final DateTime data;
  final String rota;
}

final FutureProvider<List<Notificacao>> notificacoesProvider =
    FutureProvider<List<Notificacao>>((Ref ref) async {
  if (ref.watch(sessaoProvider) == null) return const <Notificacao>[];
  final Map<String, dynamic> corpo =
      await ref.watch(apiClientProvider).notificacoes();
  return <Notificacao>[
    for (final dynamic n in corpo['notificacoes'] as List<dynamic>)
      Notificacao.deJson(n as Map<String, dynamic>),
  ];
});

class NotificacoesVistasNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void marcar(Iterable<String> ids) => state = <String>{...state, ...ids};
}

final NotifierProvider<NotificacoesVistasNotifier, Set<String>>
    notificacoesVistasProvider =
    NotifierProvider<NotificacoesVistasNotifier, Set<String>>(
        NotificacoesVistasNotifier.new);

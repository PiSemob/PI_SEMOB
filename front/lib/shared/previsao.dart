import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';

@immutable
class DiaPrevisto {
  const DiaPrevisto({
    required this.data,
    required this.previsto,
    required this.minimo,
    required this.maximo,
  });

  factory DiaPrevisto.deJson(Map<String, dynamic> j) => DiaPrevisto(
        data: DateTime.parse(j['data'] as String),
        previsto: (j['previsto'] as num).toDouble(),
        minimo: (j['minimo'] as num).toDouble(),
        maximo: (j['maximo'] as num).toDouble(),
      );

  final DateTime data;
  final double previsto;
  final double minimo;
  final double maximo;
}

@immutable
class Previsao {
  const Previsao({
    required this.modelo,
    required this.dias,
    this.mape,
  });

  factory Previsao.deJson(Map<String, dynamic> j) {
    final Map<String, dynamic>? erro =
        j['erro_na_validacao'] as Map<String, dynamic>?;
    return Previsao(
      modelo: j['modelo'] as String,
      mape: (erro?['mape'] as num?)?.toDouble(),
      dias: <DiaPrevisto>[
        for (final dynamic d in j['previsao'] as List<dynamic>)
          DiaPrevisto.deJson(d as Map<String, dynamic>),
      ],
    );
  }

  final String modelo;

  /// Erro percentual médio nos últimos 14 dias conhecidos, escondidos do treino.
  final double? mape;
  final List<DiaPrevisto> dias;

  String get nomeModelo => switch (modelo) {
        'prophet' => 'Prophet',
        'sarimax' => 'SARIMAX',
        _ => modelo,
      };
}

typedef PedidoPrevisao = ({String alvo, String? linha});

/// Cada série é pedida uma vez e fica guardada enquanto o app estiver aberto.
final FutureProviderFamily<Previsao, PedidoPrevisao> previsaoProvider =
    FutureProvider.family<Previsao, PedidoPrevisao>(
  (Ref ref, PedidoPrevisao pedido) async => Previsao.deJson(
    await ref
        .watch(apiClientProvider)
        .previsao(alvo: pedido.alvo, linha: pedido.linha),
  ),
);

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';

const Map<String, String> _variaveis = <String, String>{
  'nr_viagens': 'Viagens',
  'km_total': 'Km',
  'km_por_viagem': 'Km por viagem',
  'duracao_media': 'Duração média',
  'nr_veiculos': 'Veículos',
};

double? _double(dynamic v) => v == null ? null : (v as num).toDouble();

/// Um dia em que uma linha fugiu do próprio padrão (Isolation Forest).
@immutable
class DiaAtipico {
  const DiaAtipico({
    required this.data,
    required this.linha,
    required this.pontuacao,
    required this.destaque,
  });

  factory DiaAtipico.deJson(Map<String, dynamic> j) => DiaAtipico(
        data: DateTime.parse(j['data'] as String),
        linha: j['linha'] as String,
        pontuacao: _double(j['pontuacao']) ?? 0,
        destaque: j['destaque'] as String? ?? '',
      );

  final DateTime data;
  final String linha;

  /// Quanto maior, mais atípico.
  final double pontuacao;

  /// Como vem do modelo: "nr_viagens: 4.5 desvios abaixo do normal".
  final String destaque;

  /// O destaque em português: "Viagens: 4,5 desvios abaixo do normal".
  String get explicacao {
    final int i = destaque.indexOf(':');
    if (i < 0) return destaque;
    final String variavel = destaque.substring(0, i);
    final String resto = destaque.substring(i + 1).trim().replaceFirstMapped(
        RegExp(r'(\d)\.(\d)'), (Match m) => '${m[1]},${m[2]}');
    return '${_variaveis[variavel] ?? variavel}: $resto';
  }
}

/// Uma viagem que não se parece com nenhuma outra da linha (DBSCAN).
@immutable
class ViagemAtipica {
  const ViagemAtipica({
    required this.inicio,
    required this.sentido,
    required this.prefixo,
    required this.duracaoMin,
    required this.km,
    required this.medianaDuracao,
    required this.medianaKm,
  });

  factory ViagemAtipica.deJson(Map<String, dynamic> j) => ViagemAtipica(
        inicio: DateTime.parse(j['inicio_realizado'] as String),
        sentido: j['sentido'] as String?,
        prefixo: j['prefixo'] as String?,
        duracaoMin: _double(j['duracao_min']),
        km: _double(j['km_total']),
        medianaDuracao: _double(j['mediana_duracao']),
        medianaKm: _double(j['mediana_km']),
      );

  final DateTime inicio;
  final String? sentido;
  final String? prefixo;
  final double? duracaoMin;
  final double? km;
  final double? medianaDuracao;
  final double? medianaKm;
}

typedef PeriodoAnomalias = ({DateTime inicio, DateTime fim});
typedef PedidoViagensAtipicas = ({String linha, DateTime inicio, DateTime fim});

List<Map<String, dynamic>> _lista(Map<String, dynamic> corpo) =>
    (corpo['anomalias'] as List<dynamic>).cast<Map<String, dynamic>>();

/// Dias atípicos de todas as linhas no período, do mais para o menos atípico.
final FutureProviderFamily<List<DiaAtipico>, PeriodoAnomalias>
    diasAtipicosProvider =
    FutureProvider.family<List<DiaAtipico>, PeriodoAnomalias>(
  (Ref ref, PeriodoAnomalias p) async => _lista(
    await ref.watch(apiClientProvider).anomalias(
          modelo: 'isolation_forest',
          inicio: p.inicio,
          fim: p.fim,
        ),
  ).map(DiaAtipico.deJson).toList(),
);

/// Viagens atípicas de uma linha no período, em ordem de horário.
final FutureProviderFamily<List<ViagemAtipica>, PedidoViagensAtipicas>
    viagensAtipicasProvider =
    FutureProvider.family<List<ViagemAtipica>, PedidoViagensAtipicas>(
  (Ref ref, PedidoViagensAtipicas p) async => _lista(
    await ref.watch(apiClientProvider).anomalias(
          modelo: 'dbscan',
          inicio: p.inicio,
          fim: p.fim,
          linha: p.linha,
        ),
  ).map(ViagemAtipica.deJson).toList(),
);

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/app_widgets.dart';
import 'widgets/mapa_municipio.dart';

int? _int(dynamic v) => v == null ? null : (v as num).round();
double? _double(dynamic v) => v == null ? null : (v as num).toDouble();

@immutable
class LinhaOnibus {
  const LinhaOnibus({
    required this.codigo,
    required this.nome,
    required this.origem,
    required this.destino,
    required this.viagens,
    required this.veiculos,
    required this.duracaoMediaMin,
  });

  factory LinhaOnibus.deJson(Map<String, dynamic> j) => LinhaOnibus(
        codigo: j['codigo'] as String,
        nome: j['nome'] as String,
        origem: j['origem'] as String,
        destino: j['destino'] as String,
        viagens: _int(j['viagens']) ?? 0,
        veiculos: _int(j['veiculos']) ?? 0,
        duracaoMediaMin: _double(j['duracao_media_min']),
      );

  final String codigo;
  final String nome;

  final String origem;

  final String destino;

  final int viagens;
  final int veiculos;
  final double? duracaoMediaMin;
}

@immutable
class DiaOperacao {
  const DiaOperacao({
    required this.data,
    this.veiculos,
    this.viagensProgramadas,
    this.viagensRealizadas,
    this.kmProdutivo,
    this.kmImprodutivo,
    this.kmTotal,
    this.catraca,
    this.antecipados,
    this.naoPagantes,
    this.passageiros,
    this.vendas,
    this.utilizacao,
    this.creditoCirculante,
    this.saldoCartoes,
  });

  factory DiaOperacao.deJson(Map<String, dynamic> j) => DiaOperacao(
        data: DateTime.parse(j['data'] as String),
        veiculos: _int(j['veiculos']),
        viagensProgramadas: _int(j['viagens_programadas']),
        viagensRealizadas: _int(j['viagens_realizadas']),
        kmProdutivo: _double(j['km_produtivo']),
        kmImprodutivo: _double(j['km_improdutivo']),
        kmTotal: _double(j['km_total']),
        catraca: _int(j['catraca']),
        antecipados: _int(j['antecipados']),
        naoPagantes: _int(j['nao_pagantes']),
        passageiros: _int(j['passageiros']),
        vendas: _double(j['vendas']),
        utilizacao: _double(j['utilizacao']),
        creditoCirculante: _double(j['credito_circulante']),
        saldoCartoes: _double(j['saldo_cartoes']),
      );

  final DateTime data;
  final int? veiculos;
  final int? viagensProgramadas;
  final int? viagensRealizadas;
  final double? kmProdutivo;
  final double? kmImprodutivo;
  final double? kmTotal;
  final int? catraca;
  final int? antecipados;
  final int? naoPagantes;
  final int? passageiros;

  final double? vendas;
  final double? utilizacao;
  final double? creditoCirculante;

  final double? saldoCartoes;
}

@immutable
class LinhaNoDia {
  const LinhaNoDia({
    required this.data,
    required this.linha,
    required this.km,
    required this.viagens,
  });

  final DateTime data;
  final String linha;
  final double km;
  final int viagens;
}

@immutable
class ViagensFaixa {
  const ViagensFaixa({
    required this.linha,
    required this.diaSemana,
    required this.faixa,
    required this.viagens,
  });

  final String linha;

  final int diaSemana;
  final int faixa;
  final double viagens;
}

@immutable
class ViagemComProblema {
  const ViagemComProblema({
    required this.data,
    required this.situacao,
    required this.linha,
    required this.atendimento,
    required this.inicioProgramado,
    required this.prefixo,
  });

  final DateTime data;
  final String situacao;
  final String linha;
  final String atendimento;
  final String? inicioProgramado;
  final String? prefixo;

  String get situacaoTexto => switch (situacao) {
        'nao_realizada' => 'Não realizada',
        'nao_iniciada' => 'Não iniciada',
        'nao_terminada' => 'Não terminada',
        _ => situacao,
      };
}

@immutable
class ArquivoRelatorio {
  const ArquivoRelatorio({
    required this.arquivo,
    required this.pasta,
    required this.geradoEm,
    required this.relatorios,
    required this.registros,
  });

  final String arquivo;
  final String pasta;
  final String geradoEm;
  final List<String> relatorios;
  final int registros;
}

@immutable
class BaseDados {
  const BaseDados({
    required this.tabela,
    required this.registros,
    required this.suspeitos,
    required this.inicio,
    required this.fim,
  });

  final String tabela;
  final int registros;
  final int suspeitos;
  final DateTime inicio;
  final DateTime fim;
}

class Painel {
  Painel({
    required this.inicio,
    required this.fim,
    required this.veiculosDistintos,
    required this.linhas,
    required this.dias,
    required this.linhasPorDia,
    required this.faixas,
    required this.problemas,
    required this.arquivos,
    required this.bases,
  });

  factory Painel.deJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> lista(String chave) =>
        (j[chave] as List<dynamic>).cast<Map<String, dynamic>>();
    return Painel(
      inicio: DateTime.parse(j['inicio'] as String),
      fim: DateTime.parse(j['fim'] as String),
      veiculosDistintos: _int(j['veiculos_distintos']) ?? 0,
      linhas: lista('linhas').map(LinhaOnibus.deJson).toList(),
      dias: lista('diario').map(DiaOperacao.deJson).toList(),
      linhasPorDia: <LinhaNoDia>[
        for (final Map<String, dynamic> r in lista('linha_dia'))
          LinhaNoDia(
            data: DateTime.parse(r['data'] as String),
            linha: r['linha'] as String,
            km: _double(r['km']) ?? 0,
            viagens: _int(r['viagens']) ?? 0,
          ),
      ],
      faixas: <ViagensFaixa>[
        for (final Map<String, dynamic> r in lista('faixa_horaria'))
          ViagensFaixa(
            linha: r['linha'] as String,
            diaSemana: _int(r['dia_sem'])!,
            faixa: _int(r['faixa'])!,
            viagens: _double(r['viagens']) ?? 0,
          ),
      ],
      problemas: <ViagemComProblema>[
        for (final Map<String, dynamic> r in lista('excecoes'))
          ViagemComProblema(
            data: DateTime.parse(r['data'] as String),
            situacao: r['situacao'] as String,
            linha: r['linha'] as String,
            atendimento: r['atendimento'] as String? ?? '',
            inicioProgramado: r['inicio_programado'] as String?,
            prefixo: r['prefixo'] as String?,
          ),
      ],
      arquivos: <ArquivoRelatorio>[
        for (final Map<String, dynamic> r in lista('arquivos'))
          ArquivoRelatorio(
            arquivo: r['arquivo'] as String,
            pasta: r['pasta'] as String,
            geradoEm: r['gerado_em'] as String,
            relatorios: (r['relatorios'] as List<dynamic>).cast<String>(),
            registros: _int(r['registros']) ?? 0,
          ),
      ],
      bases: <BaseDados>[
        for (final Map<String, dynamic> r in lista('bases'))
          BaseDados(
            tabela: r['tabela'] as String,
            registros: _int(r['registros']) ?? 0,
            suspeitos: _int(r['suspeitos']) ?? 0,
            inicio: DateTime.parse(r['inicio'] as String),
            fim: DateTime.parse(r['fim'] as String),
          ),
      ],
    );
  }

  static Future<Painel> carregar(AssetBundle bundle) async => Painel.deJson(
        jsonDecode(await bundle.loadString('assets/dados/painel.json'))
            as Map<String, dynamic>,
      );

  final DateTime inicio;
  final DateTime fim;
  final int veiculosDistintos;
  final List<LinhaOnibus> linhas;
  final List<DiaOperacao> dias;
  final List<LinhaNoDia> linhasPorDia;
  final List<ViagensFaixa> faixas;
  final List<ViagemComProblema> problemas;
  final List<ArquivoRelatorio> arquivos;
  final List<BaseDados> bases;

  LinhaOnibus? linha(String codigo) {
    for (final LinhaOnibus l in linhas) {
      if (l.codigo == codigo) return l;
    }
    return null;
  }

  static bool _dentro(DateTime d, DateTime inicio, DateTime fim) =>
      !d.isBefore(inicio) && !d.isAfter(fim);

  List<DiaOperacao> diasEntre(DateTime inicio, DateTime fim) =>
      dias.where((DiaOperacao d) => _dentro(d.data, inicio, fim)).toList();

  List<DiaOperacao> diasAntes(DateTime inicio, DateTime fim) {
    final int n = fim.difference(inicio).inDays + 1;
    final DateTime fimAnterior = inicio.subtract(const Duration(days: 1));
    return diasEntre(fimAnterior.subtract(Duration(days: n - 1)), fimAnterior);
  }

  List<LinhaNoDia> linhasEntre(DateTime inicio, DateTime fim) => linhasPorDia
      .where((LinhaNoDia l) => _dentro(l.data, inicio, fim))
      .toList();

  List<ViagemComProblema> problemasEntre(DateTime inicio, DateTime fim) =>
      problemas
          .where((ViagemComProblema p) => _dentro(p.data, inicio, fim))
          .toList();

  Map<String, int> viagensPorLinha(DateTime inicio, DateTime fim) {
    final Map<String, int> total = <String, int>{};
    for (final LinhaNoDia l in linhasEntre(inicio, fim)) {
      total[l.linha] = (total[l.linha] ?? 0) + l.viagens;
    }
    return total;
  }
}

final FutureProvider<Painel> painelProvider =
    FutureProvider<Painel>((Ref ref) => Painel.carregar(rootBundle));

class ComPainel extends ConsumerWidget {
  const ComPainel({super.key, required this.builder});

  final Widget Function(BuildContext context, Painel painel) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(painelProvider).when(
          data: (Painel p) => builder(context, p),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (Object e, StackTrace _) => Center(
            child: EmptyState(
              icone: Icons.error_outline,
              mensagem: 'Não foi possível ler os dados do painel.\n$e',
            ),
          ),
        );
  }
}

List<FluxoMapa> fluxosDasLinhas(
  Painel painel,
  Map<String, int> viagens, {
  String? destaque,
}) {
  final Map<String, int> repetidos = <String, int>{};
  return <FluxoMapa>[
    for (final LinhaOnibus l in painel.linhas)
      if ((viagens[l.codigo] ?? 0) > 0)
        () {
          final String trajeto = '${l.origem}>${l.destino}';
          final int ordem = repetidos[trajeto] = (repetidos[trajeto] ?? -1) + 1;
          return FluxoMapa(
            origem: l.origem,
            destino: l.destino,
            peso: viagens[l.codigo]!.toDouble(),
            destaque: l.codigo == destaque,
            curvatura: 1 + 0.4 * ordem,
          );
        }(),
  ];
}

int somar(Iterable<int?> valores) =>
    valores.fold(0, (int a, int? v) => a + (v ?? 0));

double somarDouble(Iterable<double?> valores) =>
    valores.fold(0, (double a, double? v) => a + (v ?? 0));

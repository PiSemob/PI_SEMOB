import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../core/autenticacao/sessao.dart' show Sessao, sessaoProvider;

import 'formatters.dart';
import 'painel.dart';

enum PeriodoTipo {
  hoje,
  ultimos7,
  ultimos15,
  ultimos30,
  mesAtual,
  personalizado
}

extension PeriodoTipoLabel on PeriodoTipo {
  String get label => switch (this) {
        PeriodoTipo.hoje => 'Último dia',
        PeriodoTipo.ultimos7 => 'Últimos 7d',
        PeriodoTipo.ultimos15 => 'Últimos 15d',
        PeriodoTipo.ultimos30 => 'Últimos 30d',
        PeriodoTipo.mesAtual => 'Último mês',
        PeriodoTipo.personalizado => 'Personalizado',
      };
}

@immutable
class FiltroPeriodo {
  const FiltroPeriodo({
    required this.tipo,
    required this.inicio,
    required this.fim,
    this.comparar = false,
  });

  factory FiltroPeriodo.deTipo(
    PeriodoTipo tipo, {
    bool comparar = false,
    DateTime? referencia,
  }) {
    final DateTime hoje = DateUtils.dateOnly(referencia ?? DateTime.now());
    final DateTime inicio = switch (tipo) {
      PeriodoTipo.hoje => hoje,
      PeriodoTipo.ultimos7 => hoje.subtract(const Duration(days: 6)),
      PeriodoTipo.ultimos15 => hoje.subtract(const Duration(days: 14)),
      PeriodoTipo.ultimos30 => hoje.subtract(const Duration(days: 29)),
      PeriodoTipo.mesAtual => DateTime(hoje.year, hoje.month),
      PeriodoTipo.personalizado => hoje,
    };
    return FiltroPeriodo(
        tipo: tipo, inicio: inicio, fim: hoje, comparar: comparar);
  }

  final PeriodoTipo tipo;
  final DateTime inicio;
  final DateTime fim;
  final bool comparar;

  String get descricao => tipo == PeriodoTipo.hoje
      ? fmtData(inicio)
      : '${fmtData(inicio)} - ${fmtData(fim)}';

  FiltroPeriodo copyWith({
    PeriodoTipo? tipo,
    DateTime? inicio,
    DateTime? fim,
    bool? comparar,
  }) {
    return FiltroPeriodo(
      tipo: tipo ?? this.tipo,
      inicio: inicio ?? this.inicio,
      fim: fim ?? this.fim,
      comparar: comparar ?? this.comparar,
    );
  }
}

class FiltroPeriodoNotifier extends Notifier<FiltroPeriodo> {
  DateTime? get _referencia => ref.watch(painelProvider).valueOrNull?.fim;

  @override
  FiltroPeriodo build() =>
      FiltroPeriodo.deTipo(PeriodoTipo.ultimos30, referencia: _referencia);

  void selecionar(PeriodoTipo tipo) {
    state = FiltroPeriodo.deTipo(
      tipo,
      comparar: state.comparar,
      referencia: ref.read(painelProvider).valueOrNull?.fim,
    );
  }

  void definirIntervalo(DateTimeRange intervalo) {
    state = state.copyWith(
      tipo: PeriodoTipo.personalizado,
      inicio: intervalo.start,
      fim: intervalo.end,
    );
  }

  void alternarComparacao() =>
      state = state.copyWith(comparar: !state.comparar);
}

final NotifierProvider<FiltroPeriodoNotifier, FiltroPeriodo>
    filtroPeriodoProvider =
    NotifierProvider<FiltroPeriodoNotifier, FiltroPeriodo>(
        FiltroPeriodoNotifier.new);

class LinhaSelecionadaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selecionar(String? linha) => state = linha;
}

final NotifierProvider<LinhaSelecionadaNotifier, String?>
    linhaSelecionadaProvider =
    NotifierProvider<LinhaSelecionadaNotifier, String?>(
        LinhaSelecionadaNotifier.new);

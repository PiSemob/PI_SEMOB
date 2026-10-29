import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'formatters.dart';

enum PeriodoTipo { hoje, ultimos7, ultimos15, ultimos30, mesAtual, personalizado }

extension PeriodoTipoLabel on PeriodoTipo {
  String get label => switch (this) {
        PeriodoTipo.hoje => 'Hoje',
        PeriodoTipo.ultimos7 => 'Últimos 7d',
        PeriodoTipo.ultimos15 => 'Últimos 15d',
        PeriodoTipo.ultimos30 => 'Últimos 30d',
        PeriodoTipo.mesAtual => 'Mês Atual',
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

  factory FiltroPeriodo.deTipo(PeriodoTipo tipo, {bool comparar = false}) {
    final DateTime hoje = DateUtils.dateOnly(DateTime.now());
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
  @override
  FiltroPeriodo build() => FiltroPeriodo.deTipo(PeriodoTipo.ultimos30);

  void selecionar(PeriodoTipo tipo) {
    state = FiltroPeriodo.deTipo(tipo, comparar: state.comparar);
  }

  void definirIntervalo(DateTimeRange intervalo) {
    state = state.copyWith(
      tipo: PeriodoTipo.personalizado,
      inicio: intervalo.start,
      fim: intervalo.end,
    );
  }

  void alternarComparacao() => state = state.copyWith(comparar: !state.comparar);
}

final NotifierProvider<FiltroPeriodoNotifier, FiltroPeriodo> filtroPeriodoProvider =
    NotifierProvider<FiltroPeriodoNotifier, FiltroPeriodo>(FiltroPeriodoNotifier.new);


@immutable
class FiltroDemanda {
  const FiltroDemanda({this.linha, this.empresa});

  final String? linha;
  final String? empresa;

  FiltroDemanda copyWith({
    String? linha,
    String? empresa,
    bool limparLinha = false,
    bool limparEmpresa = false,
  }) {
    return FiltroDemanda(
      linha: limparLinha ? null : (linha ?? this.linha),
      empresa: limparEmpresa ? null : (empresa ?? this.empresa),
    );
  }
}

class FiltroDemandaNotifier extends Notifier<FiltroDemanda> {
  @override
  FiltroDemanda build() => const FiltroDemanda();

  void setLinha(String? linha) =>
      state = state.copyWith(linha: linha, limparLinha: linha == null);

  void setEmpresa(String? empresa) =>
      state = state.copyWith(empresa: empresa, limparEmpresa: empresa == null);
}

final NotifierProvider<FiltroDemandaNotifier, FiltroDemanda> filtroDemandaProvider =
    NotifierProvider<FiltroDemandaNotifier, FiltroDemanda>(FiltroDemandaNotifier.new);

class SessaoNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void entrar(String email) => state = email;

  void sair() => state = null;
}

final NotifierProvider<SessaoNotifier, String?> sessaoProvider =
    NotifierProvider<SessaoNotifier, String?>(SessaoNotifier.new);


@immutable
class Mensagem {
  const Mensagem({required this.texto, required this.doUsuario});

  final String texto;
  final bool doUsuario;
}

@immutable
class Conversa {
  const Conversa({required this.id, required this.titulo, required this.mensagens});

  final String id;
  final String titulo;
  final List<Mensagem> mensagens;

  Conversa copyWith({String? titulo, List<Mensagem>? mensagens}) => Conversa(
        id: id,
        titulo: titulo ?? this.titulo,
        mensagens: mensagens ?? this.mensagens,
      );
}

@immutable
class EstadoAssistente {
  const EstadoAssistente({required this.conversas, required this.selecionadaId});

  final List<Conversa> conversas;
  final String selecionadaId;

  Conversa get atual => conversas.firstWhere((Conversa c) => c.id == selecionadaId);
}

class AssistenteNotifier extends Notifier<EstadoAssistente> {
  @override
  EstadoAssistente build() {
    const Conversa inicial = Conversa(id: '1', titulo: 'Nova conversa', mensagens: <Mensagem>[]);
    return const EstadoAssistente(conversas: <Conversa>[inicial], selecionadaId: '1');
  }

  void novaConversa() {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    state = EstadoAssistente(
      conversas: <Conversa>[
        Conversa(id: id, titulo: 'Nova conversa', mensagens: const <Mensagem>[]),
        ...state.conversas,
      ],
      selecionadaId: id,
    );
  }

  void selecionar(String id) =>
      state = EstadoAssistente(conversas: state.conversas, selecionadaId: id);

  void enviar(String texto) {
    final String conteudo = texto.trim();
    if (conteudo.isEmpty) return;

    final Conversa atual = state.atual;
    final List<Mensagem> mensagens = <Mensagem>[
      ...atual.mensagens,
      Mensagem(texto: conteudo, doUsuario: true),
      const Mensagem(
        texto: 'Interface de demonstracao: a integracao com IA sera adicionada '
            'quando o backend do Ferret estiver disponível.',
        doUsuario: false,
      ),
    ];

    final Conversa atualizada = atual.copyWith(
      mensagens: mensagens,
      titulo: atual.mensagens.isEmpty ? conteudo : atual.titulo,
    );

    state = EstadoAssistente(
      conversas: <Conversa>[
        for (final Conversa c in state.conversas)
          if (c.id == atualizada.id) atualizada else c,
      ],
      selecionadaId: state.selecionadaId,
    );
  }
}

final NotifierProvider<AssistenteNotifier, EstadoAssistente> assistenteProvider =
    NotifierProvider<AssistenteNotifier, EstadoAssistente>(AssistenteNotifier.new);

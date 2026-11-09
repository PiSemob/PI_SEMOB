import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../shared/widgets/cartao_dados.dart';

@immutable
class Mensagem {
  const Mensagem({
    required this.texto,
    required this.doUsuario,
    this.dados = const <DadosTela>[],
    this.erro = false,
  });

  factory Mensagem.deJson(Map<String, dynamic> j) {
    return Mensagem(
      texto: (j['texto'] as String?) ?? '',
      doUsuario: j['papel'] == 'usuario',
      dados: <DadosTela>[
        for (final dynamic d in (j['dados'] as List<dynamic>?) ?? <dynamic>[])
          DadosTela.deJson(d as Map<String, dynamic>),
      ],
    );
  }

  final String texto;
  final bool doUsuario;
  final List<DadosTela> dados;
  final bool erro;
}

const String _prefixoLocal = 'nova-';

@immutable
class Conversa {
  const Conversa({
    required this.id,
    required this.titulo,
    required this.mensagens,
    this.carregada = true,
  });

  final String id;
  final String titulo;
  final List<Mensagem> mensagens;

  final bool carregada;

  bool get local => id.startsWith(_prefixoLocal);

  Conversa copyWith(
          {String? id,
          String? titulo,
          List<Mensagem>? mensagens,
          bool? carregada}) =>
      Conversa(
        id: id ?? this.id,
        titulo: titulo ?? this.titulo,
        mensagens: mensagens ?? this.mensagens,
        carregada: carregada ?? this.carregada,
      );
}

@immutable
class EstadoAssistente {
  const EstadoAssistente({
    required this.conversas,
    required this.selecionadaId,
    this.enviando = false,
    this.carregando = false,
  });

  final List<Conversa> conversas;
  final String selecionadaId;
  final bool enviando;
  final bool carregando;

  Conversa get atual =>
      conversas.firstWhere((Conversa c) => c.id == selecionadaId,
          orElse: () => conversas.first);

  EstadoAssistente copyWith({
    List<Conversa>? conversas,
    String? selecionadaId,
    bool? enviando,
    bool? carregando,
  }) =>
      EstadoAssistente(
        conversas: conversas ?? this.conversas,
        selecionadaId: selecionadaId ?? this.selecionadaId,
        enviando: enviando ?? this.enviando,
        carregando: carregando ?? this.carregando,
      );
}

class AssistenteNotifier extends Notifier<EstadoAssistente> {
  int _contador = 0;

  ApiClient get _api => ref.read(apiClientProvider);

  Conversa _nova() => Conversa(
      id: '$_prefixoLocal${_contador++}',
      titulo: 'Nova conversa',
      mensagens: const <Mensagem>[]);

  @override
  EstadoAssistente build() {
    final Conversa inicial = _nova();
    Future<void>.microtask(carregarHistorico);
    return EstadoAssistente(
        conversas: <Conversa>[inicial], selecionadaId: inicial.id);
  }

  Future<void> carregarHistorico() async {
    state = state.copyWith(carregando: true);
    try {
      final List<dynamic> lista = await _api.conversas();
      final List<Conversa> antigas = <Conversa>[
        for (final dynamic item in lista)
          Conversa(
            id: (item as Map<String, dynamic>)['id'] as String,
            titulo: item['titulo'] as String,
            mensagens: const <Mensagem>[],
            carregada: false,
          ),
      ];
      final List<Conversa> locais = state.conversas
          .where((Conversa c) => c.local || c.carregada)
          .toList();
      final Set<String> ids = locais.map((Conversa c) => c.id).toSet();
      state = state.copyWith(
        conversas: <Conversa>[
          ...locais,
          ...antigas.where((Conversa c) => !ids.contains(c.id)),
        ],
        carregando: false,
      );
    } on ErroApi {
      state = state.copyWith(carregando: false);
    }
  }

  void novaConversa() {
    final Conversa atual = state.atual;
    if (atual.local && atual.mensagens.isEmpty) return;
    final Conversa nova = _nova();
    state = state.copyWith(
        conversas: <Conversa>[nova, ...state.conversas],
        selecionadaId: nova.id);
  }

  Future<void> selecionar(String id) async {
    state = state.copyWith(selecionadaId: id);
    final Conversa conversa = state.atual;
    if (conversa.carregada) return;
    try {
      final Map<String, dynamic> corpo = await _api.conversa(id);
      _trocar(
        conversa.copyWith(
          carregada: true,
          mensagens: <Mensagem>[
            for (final dynamic m in corpo['mensagens'] as List<dynamic>)
              Mensagem.deJson(m as Map<String, dynamic>),
          ],
        ),
      );
    } on ErroApi catch (erro) {
      _trocar(conversa.copyWith(
        carregada: true,
        mensagens: <Mensagem>[
          Mensagem(
              texto: 'Não consegui abrir esta conversa. $erro',
              doUsuario: false,
              erro: true),
        ],
      ));
    }
  }

  Future<void> apagar(String id) async {
    final Conversa? conversa =
        state.conversas.where((Conversa c) => c.id == id).firstOrNull;
    if (conversa == null) return;
    if (!conversa.local) {
      try {
        await _api.apagarConversa(id);
      } on ErroApi {
        return;
      }
    }
    final List<Conversa> restantes =
        state.conversas.where((Conversa c) => c.id != id).toList();
    if (restantes.isEmpty) restantes.add(_nova());
    state = state.copyWith(
      conversas: restantes,
      selecionadaId:
          state.selecionadaId == id ? restantes.first.id : state.selecionadaId,
    );
  }

  Future<void> enviar(String texto) async {
    final String conteudo = texto.trim();
    if (conteudo.isEmpty || state.enviando) return;

    final Conversa atual = state.atual;
    _trocar(
      atual.copyWith(
        titulo: atual.mensagens.isEmpty ? conteudo : atual.titulo,
        mensagens: <Mensagem>[
          ...atual.mensagens,
          Mensagem(texto: conteudo, doUsuario: true),
        ],
      ),
    );
    state = state.copyWith(enviando: true);

    try {
      final Map<String, dynamic> corpo = await _api.conversar(conteudo,
          conversaId: atual.local ? null : atual.id);
      final Map<String, dynamic> resposta =
          corpo['resposta'] as Map<String, dynamic>;
      final Conversa agora = _buscar(atual.id);
      final Conversa respondida = agora.copyWith(
        id: corpo['conversa_id'] as String,
        titulo: corpo['titulo'] as String,
        mensagens: <Mensagem>[
          ...agora.mensagens,
          Mensagem.deJson(
              <String, dynamic>{...resposta, 'papel': 'assistente'}),
        ],
      );
      _trocar(respondida, idAntigo: atual.id);
      if (state.selecionadaId == atual.id) {
        state = state.copyWith(selecionadaId: respondida.id);
      }
    } on ErroApi catch (erro) {
      final Conversa agora = _buscar(atual.id);
      _trocar(agora.copyWith(mensagens: <Mensagem>[
        ...agora.mensagens,
        Mensagem(
          texto: erro.naoAutorizado
              ? 'Sua sessão expirou. Entre de novo para continuar.'
              : 'Não consegui responder agora: $erro',
          doUsuario: false,
          erro: true,
        ),
      ]));
    } finally {
      state = state.copyWith(enviando: false);
    }
  }

  Conversa _buscar(String id) =>
      state.conversas.firstWhere((Conversa c) => c.id == id);

  void _trocar(Conversa conversa, {String? idAntigo}) {
    final String alvo = idAntigo ?? conversa.id;
    state = state.copyWith(conversas: <Conversa>[
      for (final Conversa c in state.conversas)
        if (c.id == alvo) conversa else c,
    ]);
  }
}

final NotifierProvider<AssistenteNotifier, EstadoAssistente>
    assistenteProvider = NotifierProvider<AssistenteNotifier, EstadoAssistente>(
        AssistenteNotifier.new);

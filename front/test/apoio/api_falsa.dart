import 'dart:typed_data';

import 'package:mobi_ai/core/api/api_client.dart';
import 'package:mobi_ai/core/autenticacao/servico_autenticacao.dart';
import 'package:mobi_ai/core/autenticacao/sessao.dart';

const Sessao sessaoDeTeste = Sessao(
    email: 'ana@semob.sp.gov.br', nome: 'Ana Souza', token: 'tk', admin: true);

class ApiFalsa extends ApiClient {
  ApiFalsa({this.erro});

  ErroApi? erro;
  final List<String> pedidos = <String>[];
  Map<String, dynamic> ajustes = <String, dynamic>{
    'organizacao': 'SEMOB-SCS',
    'cidade': 'São Caetano do Sul',
    'alertas_anomalia': true,
    'relatorios_automaticos': false,
    'email_relatorios': '',
  };
  Map<String, dynamic>? ultimoSalvo;
  List<Map<String, dynamic>> cadastrados = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 1,
      'email': 'ana@semob.sp.gov.br',
      'nome': 'Ana Souza',
      'admin': true,
      'pendente': false,
    },
    <String, dynamic>{
      'id': 2,
      'email': 'bruno@semob.sp.gov.br',
      'nome': 'Bruno Lima',
      'admin': false,
      'pendente': true,
    },
  ];

  void _registrar(String pedido) {
    pedidos.add(pedido);
    if (erro != null) throw erro!;
  }

  @override
  Future<bool> estaNoAr() async => true;

  @override
  Future<List<dynamic>> conversas() async {
    _registrar('conversas');
    return <dynamic>[
      <String, dynamic>{
        'id': 'antiga',
        'titulo': 'Conversa de ontem',
        'atualizada_em': '2026-11-05T10:00:00'
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> conversa(String id) async {
    _registrar('conversa:$id');
    return <String, dynamic>{
      'id': id,
      'titulo': 'Conversa de ontem',
      'mensagens': <dynamic>[
        <String, dynamic>{'papel': 'usuario', 'texto': 'Pergunta antiga'},
        <String, dynamic>{
          'papel': 'assistente',
          'texto': 'Resposta antiga',
          'decisao': <String, dynamic>{'origem': 'regras'},
          'dados': <dynamic>[],
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> conversar(String mensagem,
      {String? conversaId}) async {
    _registrar('chat:$mensagem:${conversaId ?? '-'}');
    return <String, dynamic>{
      'conversa_id': 'c1',
      'titulo': mensagem,
      'resposta': <String, dynamic>{
        'texto': 'A linha 03 foi a que mais fez viagens: 5.848.',
        'decisao': <String, dynamic>{'opcao': 'consulta', 'origem': 'regras'},
        'dados': <dynamic>[
          <String, dynamic>{
            'titulo': 'Viagens por linha · 01/08/2026 a 31/08/2026',
            'indicadores': <dynamic>[
              <String, dynamic>{
                'nome': 'Linhas com operação',
                'valor': 9,
                'unidade': ''
              },
            ],
            'tabela': <String, dynamic>{
              'colunas': <dynamic>['Linha', 'Viagens'],
              'linhas': <dynamic>[
                <dynamic>['03', 5848],
                <dynamic>['08', 1676],
              ],
            },
          },
        ],
      },
    };
  }

  @override
  Future<void> apagarConversa(String id) async => _registrar('apagar:$id');

  @override
  Future<Map<String, dynamic>> gerarRelatorio({
    required String modelo,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    _registrar('gerar:$modelo');
    return <String, dynamic>{
      'modelo': modelo,
      'titulo': 'Relatório Executivo',
      'organizacao': 'SEMOB-SCS',
      'cidade': 'São Caetano do Sul',
      'inicio': dataParaApi(inicio),
      'fim': dataParaApi(fim),
      'gerado_em': '2026-11-06T10:30:00',
      'resumo': 'Em agosto, o cumprimento foi de 99,84%.',
      'secoes': <dynamic>[
        <String, dynamic>{
          'titulo': 'Visão geral da operação',
          'texto': 'Foram 34.994 viagens.',
          'indicadores': <dynamic>[
            <String, dynamic>{
              'nome': 'Cumprimento',
              'valor': 99.84,
              'unidade': '%'
            },
          ],
          'tabela': null,
        },
      ],
    };
  }

  @override
  Future<ArquivoBaixado> exportarRelatorio({
    required String modelo,
    required DateTime inicio,
    required DateTime fim,
    required String formato,
    Map<String, dynamic>? relatorio,
  }) async {
    _registrar('exportar:$formato:${relatorio == null ? 'novo' : 'gerado'}');
    return ArquivoBaixado(
        nome: 'relatorio.$formato',
        tipo: 'application/octet-stream',
        bytes: Uint8List(4));
  }

  @override
  Future<Map<String, dynamic>> configuracoes() async {
    _registrar('configuracoes');
    return ajustes;
  }

  @override
  Future<Map<String, dynamic>> salvarConfiguracoes(
      Map<String, dynamic> mudancas) async {
    _registrar('salvar');
    ultimoSalvo = mudancas;
    ajustes = <String, dynamic>{...ajustes, ...mudancas};
    return ajustes;
  }

  @override
  Future<List<dynamic>> usuarios() async {
    _registrar('usuarios');
    return cadastrados;
  }

  @override
  Future<void> convidarUsuario(
      {required String email,
      required String nome,
      required bool admin}) async {
    _registrar('convidar:$email:$nome:$admin');
    cadastrados = <Map<String, dynamic>>[
      ...cadastrados,
      <String, dynamic>{
        'id': cadastrados.length + 1,
        'email': email,
        'nome': nome,
        'admin': admin,
        'pendente': true,
      },
    ];
  }

  @override
  Future<void> reenviarConvite(int id) async => _registrar('reenviar:$id');

  @override
  Future<void> definirAdministrador(int id, {required bool admin}) async =>
      _registrar('admin:$id:$admin');

  @override
  Future<void> removerUsuario(int id) async {
    _registrar('remover:$id');
    cadastrados =
        cadastrados.where((Map<String, dynamic> u) => u['id'] != id).toList();
  }

  @override
  Future<Map<String, dynamic>> notificacoes() async {
    _registrar('notificacoes');
    return <String, dynamic>{
      'quantidade': 1,
      'notificacoes': <dynamic>[
        <String, dynamic>{
          'id': 'atipico-1',
          'tipo': 'anomalia',
          'titulo': 'Linha 08 fora do padrão em 11/09/2026',
          'texto': 'nr_viagens abaixo do normal',
          'data': '2026-09-11',
          'rota': '/operacao?aba=frota',
        },
      ],
    };
  }
}

class ServicoFalso implements ServicoAutenticacao {
  final List<String> chamadas = <String>[];

  @override
  bool get demonstracao => false;

  @override
  Future<Sessao> entrar(String email, String senha) async {
    chamadas.add('entrar:$email');
    if (senha != 'senha-certa') {
      throw const ErroAutenticacao('E-mail ou senha incorretos.');
    }
    return Sessao(email: email, nome: 'Ana Souza', token: 'tk');
  }

  @override
  Future<void> sair() async => chamadas.add('sair');

  @override
  Future<void> pedirRecuperacao(String email) async =>
      chamadas.add('recuperar:$email');

  @override
  Future<void> redefinirSenha(
          {required String token, required String novaSenha}) async =>
      chamadas.add('redefinir');
}

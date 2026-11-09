class PontoSerie {
  const PontoSerie(this.rotulo, this.valor);

  final String rotulo;
  final double valor;
}

class ModeloRelatorio {
  const ModeloRelatorio({
    required this.id,
    required this.icone,
    required this.nome,
    required this.descricao,
  });

  final String id;
  final String icone;
  final String nome;
  final String descricao;
}

class DadosExemplo {
  const DadosExemplo._();

  static const List<ModeloRelatorio> modelosRelatorio = <ModeloRelatorio>[
    ModeloRelatorio(
      id: 'executivo',
      icone: '📊',
      nome: 'Relatório Executivo',
      descricao: 'Resumo estratégico para prefeito e gestores',
    ),
    ModeloRelatorio(
      id: 'operacional',
      icone: '🚌',
      nome: 'Relatório Operacional',
      descricao: 'Viagens, frota, quilometragem e cumprimento',
    ),
    ModeloRelatorio(
      id: 'financeiro',
      icone: '💰',
      nome: 'Relatório Financeiro',
      descricao: 'Venda e utilização de créditos, saldo em circulação',
    ),
    ModeloRelatorio(
      id: 'prestacao_contas',
      icone: '📋',
      nome: 'Prestação de Contas',
      descricao: 'Relatório regulatório para SEMOB-SCS',
    ),
  ];

  static const List<String> sugestoesAssistente = <String>[
    'Qual linha fez mais viagens em agosto?',
    'Quantos passageiros não pagantes tivemos na última semana?',
    'Em que horário a frota tem mais partidas?',
    'Quais viagens não foram realizadas em setembro?',
    'Como estão as vendas de créditos comparadas à utilização?',
    'Qual foi o cumprimento de viagens do último mês?',
  ];
}

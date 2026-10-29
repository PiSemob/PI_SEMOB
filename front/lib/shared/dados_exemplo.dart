/// dados ficticios para popular front
library;

import 'package:intl/intl.dart';

class PontoSerie {
  const PontoSerie(this.rotulo, this.valor);

  final String rotulo;
  final double valor;
}

class Empresa {
  const Empresa({
    required this.sigla,
    required this.nome,
    required this.receita,
    required this.participacao,
  });

  final String sigla;
  final String nome;
  final double receita;
  final int participacao;
}

class Veiculo {
  const Veiculo({
    required this.prefixo,
    required this.linha,
    required this.destino,
    required this.status,
  });

  final String prefixo;
  final String linha;
  final String destino;
  final String status; 
}

class LinhaOnibus {
  const LinhaOnibus({
    required this.codigo,
    required this.nome,
    required this.empresa,
    required this.kmHoje,
    required this.kmMes,
    required this.metaMes,
    required this.viagens,
  });

  final String codigo;
  final String nome;
  final String empresa;
  final int kmHoje;
  final int kmMes;
  final int metaMes;
  final int viagens;

  int get atingimento => (kmMes / metaMes * 100).round();
  int get kmPorViagem => (kmHoje / viagens).round();
}

class DocumentoPdf {
  const DocumentoPdf({
    required this.arquivo,
    required this.empresa,
    required this.status,
    required this.data,
    required this.registros,
  });

  final String arquivo;
  final String empresa;
  final String status; 
  final String data;
  final String registros;
}

class ModeloRelatorio {
  const ModeloRelatorio({
    required this.icone,
    required this.nome,
    required this.descricao,
  });

  final String icone;
  final String nome;
  final String descricao;
}

class FonteDados {
  const FonteDados({
    required this.icone,
    required this.nome,
    required this.status,
    required this.protocolo,
    required this.detalhe,
    required this.ultimaSync,
    this.erro,
  });

  final String icone;
  final String nome;
  final String status; 
  final String protocolo;
  final String detalhe;
  final String ultimaSync;
  final String? erro;
}

class DadosExemplo {
  const DadosExemplo._();

  static final DateFormat _diaMes = DateFormat('dd/MM');

  static List<PontoSerie> serieDiaria(double base, {int dias = 30, int fase = 0}) {
    final DateTime hoje = DateTime.now();
    final List<PontoSerie> pontos = <PontoSerie>[];
    for (int i = dias - 1; i >= 0; i--) {
      final DateTime d = hoje.subtract(Duration(days: i));
      final double fator = d.weekday >= 6 ? 0.52 : 0.94 + ((i + fase) % 7) * 0.02;
      pontos.add(PontoSerie(_diaMes.format(d), base * fator));
    }
    return pontos;
  }

  static const List<String> meses = <String>[
    'Out/25', 'Nov/25', 'Dez/25', 'Jan/26', 'Fev/26', 'Mar/26',
    'Abr/26', 'Mai/26', 'Jun/26', 'Jul/26', 'Ago/26', 'Set/26',
  ];

  static List<PontoSerie> serieMensal(double base, {int fase = 0}) {
    const List<double> variacao = <double>[
      0.88, 0.92, 0.85, 0.90, 0.87, 0.95,
      0.97, 1.00, 0.96, 0.93, 1.02, 0.99,
    ];
    double ajuste(int i) => fase == 0 ? 1 : 1 + (((i + 1) * fase) % 5 - 2) * 0.015;
    return <PontoSerie>[
      for (int i = 0; i < meses.length; i++)
        PontoSerie(meses[i], base * variacao[i] * ajuste(i)),
    ];
  }

  static const double passageirosHoje = 34800;
  static const double receitaHoje = 78039;
  static const double pagantesHoje = 27144;
  static const double gratuidadesHoje = 7656;

  static const List<PontoSerie> formasPagamento = <PontoSerie>[
    PontoSerie('Bilhete', 18096),
    PontoSerie('Gratuidade', gratuidadesHoje),
    PontoSerie('Débito', 5220),
    PontoSerie('Crédito', 3828),
  ];

  static const double _passageirosMes = 950000;

  static int get _viagensTotais =>
      linhas.fold(0, (int soma, LinhaOnibus l) => soma + l.viagens);

  /// Linhas que passam pelos filtros. `empresa` é a sigla (ABC, MET, NSC).
  static List<LinhaOnibus> linhasFiltradas({String? linha, String? empresa}) {
    final String? nomeEmpresa = empresa == null
        ? null
        : empresas.firstWhere((Empresa e) => e.sigla == empresa).nome;
    return <LinhaOnibus>[
      for (final LinhaOnibus l in linhas)
        if ((linha == null || l.codigo == linha) &&
            (nomeEmpresa == null || l.empresa == nomeEmpresa))
          l,
    ];
  }

  /// Passageiros por dia do sistema todo (`linha` nula) ou de uma linha.
  static List<PontoSerie> passageirosDiarios({String? linha, int dias = 30}) {
    if (linha == null) return serieDiaria(passageirosHoje, dias: dias);
    final int i = linhas.indexWhere((LinhaOnibus l) => l.codigo == linha);
    final double base = passageirosHoje * linhas[i].viagens / _viagensTotais;
    return serieDiaria(base, dias: dias, fase: i + 1);
  }

  /// Receita por dia, na mesma proporção receita/passageiro do dashboard.
  static List<PontoSerie> receitaDiaria({String? linha, int dias = 30}) {
    const double porPassageiro = receitaHoje / passageirosHoje;
    return <PontoSerie>[
      for (final PontoSerie p in passageirosDiarios(linha: linha, dias: dias))
        PontoSerie(p.rotulo, p.valor * porPassageiro),
    ];
  }

  /// Passageiros por mês, somando as linhas.
  static List<PontoSerie> passageirosMensais(List<LinhaOnibus> selecionadas) {
    if (selecionadas.isEmpty) return const <PontoSerie>[];
    final List<double> soma = List<double>.filled(meses.length, 0);
    for (final LinhaOnibus l in selecionadas) {
      final double base = _passageirosMes * l.viagens / _viagensTotais;
      final List<PontoSerie> serie = serieMensal(base, fase: linhas.indexOf(l) + 1);
      for (int i = 0; i < meses.length; i++) {
        soma[i] += serie[i].valor;
      }
    }
    return <PontoSerie>[
      for (int i = 0; i < meses.length; i++) PontoSerie(meses[i], soma[i]),
    ];
  }

  /// Passageiros estimados de uma linha no mês mais recente.
  static double passageirosNoMes(LinhaOnibus l) =>
      passageirosMensais(<LinhaOnibus>[l]).last.valor;

  static const List<Empresa> empresas = <Empresa>[
    Empresa(
      sigla: 'ABC',
      nome: 'AUTOBUS SCS Ltda',
      receita: 889237,
      participacao: 42,
    ),
    Empresa(
      sigla: 'MET',
      nome: 'METROPOLITAN Transporte',
      receita: 741031,
      participacao: 35,
    ),
    Empresa(
      sigla: 'NSC',
      nome: 'NOVA SCS Mobilidade',
      receita: 486963,
      participacao: 23,
    ),
  ];

  static const List<LinhaOnibus> linhas = <LinhaOnibus>[
    LinhaOnibus(
      codigo: 'L01',
      nome: 'Centro / Term. Santa Paula',
      empresa: 'AUTOBUS SCS Ltda',
      kmHoje: 640,
      kmMes: 21892,
      metaMes: 20000,
      viagens: 20,
    ),
    LinhaOnibus(
      codigo: 'L02',
      nome: 'Term. SCS Centro / Barcelona',
      empresa: 'AUTOBUS SCS Ltda',
      kmHoje: 728,
      kmMes: 24306,
      metaMes: 20000,
      viagens: 27,
    ),
    LinhaOnibus(
      codigo: 'L03',
      nome: 'Fundação / Centro',
      empresa: 'METROPOLITAN Transporte',
      kmHoje: 845,
      kmMes: 18840,
      metaMes: 20000,
      viagens: 26,
    ),
    LinhaOnibus(
      codigo: 'L04',
      nome: 'Cerâmica / Praça Mauá',
      empresa: 'METROPOLITAN Transporte',
      kmHoje: 768,
      kmMes: 28465,
      metaMes: 20000,
      viagens: 25,
    ),
    LinhaOnibus(
      codigo: 'L05',
      nome: 'Nova Gerti / Term. SCS',
      empresa: 'METROPOLITAN Transporte',
      kmHoje: 751,
      kmMes: 25402,
      metaMes: 20000,
      viagens: 24,
    ),
    LinhaOnibus(
      codigo: 'L06',
      nome: 'Prosperidade / Centro',
      empresa: 'NOVA SCS Mobilidade',
      kmHoje: 690,
      kmMes: 19757,
      metaMes: 20000,
      viagens: 22,
    ),
    LinhaOnibus(
      codigo: 'L07',
      nome: 'Olímpico / Term. Santa Paula',
      empresa: 'NOVA SCS Mobilidade',
      kmHoje: 785,
      kmMes: 28809,
      metaMes: 20000,
      viagens: 23,
    ),
    LinhaOnibus(
      codigo: 'L08',
      nome: 'Mauá / Term. SCS Centro',
      empresa: 'NOVA SCS Mobilidade',
      kmHoje: 626,
      kmMes: 27971,
      metaMes: 20000,
      viagens: 20,
    ),
  ];

  static const List<Veiculo> veiculos = <Veiculo>[
    Veiculo(
      prefixo: 'SCS-1042',
      linha: 'L01',
      destino: 'Term. Santa Paula',
      status: 'Em rota',
    ),
    Veiculo(
      prefixo: 'SCS-1043',
      linha: 'L01',
      destino: 'Praça Mauá',
      status: 'Em rota',
    ),
    Veiculo(
      prefixo: 'SCS-2011',
      linha: 'L02',
      destino: 'Term. SCS Centro',
      status: 'Parado',
    ),
    Veiculo(
      prefixo: 'SCS-2012',
      linha: 'L02',
      destino: 'Barcelona',
      status: 'Atenção',
    ),
    Veiculo(
      prefixo: 'SCS-3001',
      linha: 'L03',
      destino: 'Fundação',
      status: 'Em rota',
    ),
    Veiculo(
      prefixo: 'SCS-4001',
      linha: 'L04',
      destino: 'Cerâmica',
      status: 'Atenção',
    ),
    Veiculo(
      prefixo: 'SCS-5001',
      linha: 'L05',
      destino: 'Nova Gerti',
      status: 'Em rota',
    ),
    Veiculo(
      prefixo: 'SCS-6001',
      linha: 'L06',
      destino: 'Prosperidade',
      status: 'Em rota',
    ),
  ];

  static const List<DocumentoPdf> documentos = <DocumentoPdf>[
    DocumentoPdf(
      arquivo: 'Relatório Operacional SET-2026.pdf',
      empresa: 'AUTOBUS SCS',
      status: 'Processado',
      data: '15/09/2026 09:12',
      registros: '2.840',
    ),
    DocumentoPdf(
      arquivo: 'Boletim de Gratuidades AGO-2026.pdf',
      empresa: 'METROPOLITAN',
      status: 'Processado',
      data: '15/09/2026 08:45',
      registros: '1.230',
    ),
    DocumentoPdf(
      arquivo: 'Planilha Km Agosto 2026.pdf',
      empresa: 'NOVA SCS',
      status: 'Processado',
      data: '14/09/2026 18:33',
      registros: '487',
    ),
    DocumentoPdf(
      arquivo: 'Relatório Receita 14-SET.pdf',
      empresa: 'AUTOBUS SCS',
      status: 'Erro',
      data: '14/09/2026 17:21',
      registros: '—',
    ),
    DocumentoPdf(
      arquivo: 'Bilhetagem Eletrônica SET.pdf',
      empresa: 'METROPOLITAN',
      status: 'Processando',
      data: '15/09/2026 09:48',
      registros: '—',
    ),
    DocumentoPdf(
      arquivo: 'GPS Frota 13-SET-2026.pdf',
      empresa: 'NOVA SCS',
      status: 'Processado',
      data: '13/09/2026 22:10',
      registros: '3.920',
    ),
    DocumentoPdf(
      arquivo: 'Auditoria Gratuidades AGO.pdf',
      empresa: 'AUTOBUS SCS',
      status: 'Processado',
      data: '12/09/2026 14:05',
      registros: '892',
    ),
  ];

  static const List<ModeloRelatorio> modelosRelatorio = <ModeloRelatorio>[
    ModeloRelatorio(
      icone: '📊',
      nome: 'Relatório Executivo',
      descricao: 'Resumo estratégico para prefeito e gestores',
    ),
    ModeloRelatorio(
      icone: '🚌',
      nome: 'Relatório Operacional',
      descricao: 'Indicadores operacionais detalhados',
    ),
    ModeloRelatorio(
      icone: '💰',
      nome: 'Relatório Financeiro',
      descricao: 'Receitas, gratuidades e análise financeira',
    ),
    ModeloRelatorio(
      icone: '📋',
      nome: 'Prestação de Contas',
      descricao: 'Relatório regulatório para SEMOB-SCS',
    ),
  ];

  static const List<FonteDados> fontesDados = <FonteDados>[
    FonteDados(
      icone: '🗄️',
      nome: 'Banco de Dados Operacional',
      status: 'Conectado',
      protocolo: 'PostgreSQL',
      detalhe: '4.2M registros',
      ultimaSync: '15/09/2026 09:52',
    ),
    FonteDados(
      icone: '📡',
      nome: 'Rastreamento GPS (AVL)',
      status: 'Conectado',
      protocolo: 'API REST',
      detalhe: '48 veículos ativos',
      ultimaSync: '15/09/2026 09:54',
    ),
    FonteDados(
      icone: '⚙️',
      nome: 'Bilhetagem Eletrônica',
      status: 'Conectado',
      protocolo: 'API SOAP',
      detalhe: '2.840 validações hoje',
      ultimaSync: '15/09/2026 09:50',
    ),
    FonteDados(
      icone: '📧',
      nome: 'E-mails Automáticos (IMAP)',
      status: 'Conectado',
      protocolo: 'IMAP/TLS',
      detalhe: '7 docs recebidos hoje',
      ultimaSync: '15/09/2026 09:30',
    ),
    FonteDados(
      icone: '🗺️',
      nome: 'HERE Maps API',
      status: 'Pendente',
      protocolo: 'API REST',
      detalhe: 'Aguardando chave',
      ultimaSync: '—',
    ),
    FonteDados(
      icone: '🏛️',
      nome: 'Portal SEMOB-SCS',
      status: 'Erro',
      protocolo: 'API REST',
      detalhe: 'Timeout na autenticação',
      ultimaSync: '14/09/2026 23:00',
      erro: 'Timeout na autenticação',
    ),
    FonteDados(
      icone: '📈',
      nome: 'IBGE — Dados Demográficos',
      status: 'Conectado',
      protocolo: 'API REST',
      detalhe: 'Atualização mensal',
      ultimaSync: '01/09/2026 00:00',
    ),
  ];

  static const List<String> sugestoesAssistente = <String>[
    'Qual linha teve maior queda de passageiros?',
    'Qual empresa apresentou menor receita no mês?',
    'Existe alguma anomalia operacional hoje?',
    'Qual a previsão de demanda para a próxima semana?',
    'Gerar relatório executivo para a gestão',
    'Comparar IPK de setembro vs agosto',
  ];

  static List<PontoSerie> get receitaPorEmpresa => <PontoSerie>[
        for (final Empresa e in empresas) PontoSerie(e.sigla, e.receita),
      ];

  static List<PontoSerie> get receitaPorLinha => <PontoSerie>[
        for (final LinhaOnibus l in linhas) PontoSerie(l.codigo, l.viagens * 640),
      ];

  static List<PontoSerie> get kmPorLinha => <PontoSerie>[
        for (final LinhaOnibus l in linhas)
          PontoSerie(l.codigo, l.kmHoje.toDouble()),
      ];

  static List<PontoSerie> get kmMesPorLinha => <PontoSerie>[
        for (final LinhaOnibus l in linhas)
          PontoSerie(l.codigo, l.kmMes.toDouble()),
      ];

  static List<PontoSerie> get metaMesPorLinha => <PontoSerie>[
        for (final LinhaOnibus l in linhas)
          PontoSerie(l.codigo, l.metaMes.toDouble()),
      ];
}

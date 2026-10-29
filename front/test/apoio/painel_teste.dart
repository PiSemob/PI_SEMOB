import 'package:mobi_ai/shared/painel.dart';

Painel painelDeTeste() => Painel.deJson(<String, dynamic>{
      'inicio': '2026-09-13',
      'fim': '2026-09-14',
      'veiculos_distintos': 3,
      'linhas': <Map<String, dynamic>>[
        for (final (String codigo, String destino) in <(String, String)>[
          ('01', 'Santa Maria'),
          ('02', 'Nova Gerty'),
          ('03', 'Barcelona'),
        ])
          <String, dynamic>{
            'codigo': codigo,
            'nome': 'Estação – $destino',
            'origem': 'Estação São Caetano',
            'destino': destino,
            'viagens': 10,
            'km': 100,
            'veiculos': 1,
            'duracao_media_min': 20,
          },
      ],
      'diario': <Map<String, dynamic>>[
        for (final String data in <String>['2026-09-13', '2026-09-14'])
          <String, dynamic>{
            'data': data,
            'veiculos': 3,
            'viagens_programadas': 10,
            'viagens_realizadas': 9,
            'km_produtivo': 90,
            'km_improdutivo': 10,
            'km_total': 100,
            'catraca': 100,
            'antecipados': 10,
            'nao_pagantes': 50,
            'passageiros': 160,
            'vendas': 1000,
            'utilizacao': 900,
            'credito_circulante': 100,
            'saldo_cartoes': 5000,
          },
      ],
      'linha_dia': <Map<String, dynamic>>[
        for (final String linha in <String>['01', '02', '03'])
          <String, dynamic>{
            'data': '2026-09-14',
            'linha': linha,
            'km': 50,
            'viagens': 5
          },
      ],
      'faixa_horaria': <Map<String, dynamic>>[
        <String, dynamic>{'linha': '', 'dia_sem': 0, 'faixa': 6, 'viagens': 4},
      ],
      'excecoes': <Map<String, dynamic>>[
        <String, dynamic>{
          'data': '2026-09-14',
          'situacao': 'nao_realizada',
          'linha': '01',
          'atendimento': 'ATENDIMENTO DA 01',
          'inicio_programado': '07:00',
          'prefixo': '1001',
        },
        <String, dynamic>{
          'data': '2026-09-14',
          'situacao': 'nao_terminada',
          'linha': '02',
          'atendimento': 'ATENDIMENTO DA 02',
          'inicio_programado': '08:00',
          'prefixo': '1002',
        },
      ],
      'arquivos': <Map<String, dynamic>>[],
      'bases': <Map<String, dynamic>>[],
    });

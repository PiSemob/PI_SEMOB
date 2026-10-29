import 'package:flutter/material.dart';

import '../../../shared/widgets/abas_pagina.dart';
import '../widgets/aba_demanda.dart';
import '../widgets/aba_frota.dart';
import '../widgets/aba_quilometragem.dart';

class OperacaoPage extends StatelessWidget {
  const OperacaoPage({super.key, this.aba});

  final String? aba;

  @override
  Widget build(BuildContext context) {
    return AbasPagina(
      inicial: aba,
      abas: <Aba>[
        Aba(
            id: 'demanda',
            titulo: 'Demanda',
            conteudo: (_) => const AbaDemanda()),
        Aba(
            id: 'frota',
            titulo: 'Operação da Frota',
            conteudo: (_) => const AbaFrota()),
        Aba(
          id: 'quilometragem',
          titulo: 'Quilometragem',
          conteudo: (_) => const AbaQuilometragem(),
        ),
      ],
    );
  }
}

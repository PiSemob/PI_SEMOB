import 'package:flutter/material.dart';

import '../../../shared/widgets/abas_pagina.dart';
import '../widgets/aba_creditos.dart';
import '../widgets/aba_receita.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key, this.aba});

  final String? aba;

  @override
  Widget build(BuildContext context) {
    return AbasPagina(
      inicial: aba,
      abas: <Aba>[
        Aba(
            id: 'receita',
            titulo: 'Receita',
            conteudo: (_) => const AbaReceita()),
        Aba(
            id: 'creditos',
            titulo: 'Créditos em Circulação',
            conteudo: (_) => const AbaCreditos()),
      ],
    );
  }
}

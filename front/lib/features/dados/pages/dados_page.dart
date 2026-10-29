import 'package:flutter/material.dart';

import '../../../shared/widgets/abas_pagina.dart';
import '../../relatorios/pages/relatorios_page.dart';
import '../widgets/aba_documentos.dart';
import '../widgets/aba_integracoes.dart';

class DadosPage extends StatelessWidget {
  const DadosPage({super.key, this.aba});

  final String? aba;

  @override
  Widget build(BuildContext context) {
    return AbasPagina(
      inicial: aba,
      abas: <Aba>[
        Aba(
            id: 'documentos',
            titulo: 'Central de Documentos',
            conteudo: (_) => const AbaDocumentos()),
        Aba(
            id: 'integracoes',
            titulo: 'Integrações de Dados',
            conteudo: (_) => const AbaIntegracoes()),
        Aba(
            id: 'relatorios',
            titulo: 'Relatórios',
            conteudo: (_) => const RelatoriosPage()),
      ],
    );
  }
}

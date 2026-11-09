import 'package:flutter/foundation.dart';

@immutable
class ConfiguracoesApp {
  const ConfiguracoesApp({
    this.organizacao = 'SEMOB-SCS',
    this.cidade = 'São Caetano do Sul',
    this.alertasAnomalia = true,
    this.relatoriosAutomaticos = false,
    this.emailRelatorios = '',
  });

  factory ConfiguracoesApp.deJson(Map<String, dynamic> j) => ConfiguracoesApp(
        organizacao: j['organizacao'] as String,
        cidade: j['cidade'] as String,
        alertasAnomalia: j['alertas_anomalia'] as bool,
        relatoriosAutomaticos: j['relatorios_automaticos'] as bool,
        emailRelatorios: (j['email_relatorios'] as String?) ?? '',
      );

  final String organizacao;
  final String cidade;
  final bool alertasAnomalia;
  final bool relatoriosAutomaticos;
  final String emailRelatorios;

  Map<String, dynamic> paraJson() => <String, dynamic>{
        'organizacao': organizacao,
        'cidade': cidade,
        'alertas_anomalia': alertasAnomalia,
        'relatorios_automaticos': relatoriosAutomaticos,
        'email_relatorios': emailRelatorios,
      };
}

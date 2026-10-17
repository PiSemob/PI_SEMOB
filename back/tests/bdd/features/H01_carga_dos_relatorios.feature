# language: pt
@H01 @RF01 @RF02 @RNF02 @RNF03
Funcionalidade: Carga dos relatórios do Smart Report
  Como analista da SEMOB
  Quero carregar os relatórios HTML do Smart Report nos bancos do sistema
  Para consultar os dados sem perder o original e sem contar nada duas vezes

  Cenário: A carga completa guarda o original e a versão limpa
    Dado os 44 relatórios HTML em dados/brutos
    Quando o script ingerir roda nos bancos vazios
    Então o MongoDB guarda 107931 viagens brutas
    E o PostgreSQL guarda 86813 viagens limpas
    E todo registro limpo aponta para o HTML de onde veio

  Cenário: Rodar a carga de novo não duplica nada
    Dado que o script ingerir já rodou uma vez
    Quando o script ingerir roda de novo
    Então nenhuma coleção nem tabela muda de tamanho

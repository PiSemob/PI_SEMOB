# language: pt
@H03 @RF04 @RF05
Funcionalidade: Sinalização de viagens suspeitas e dias atípicos
  Como fiscal da SEMOB
  Quero que o sistema aponte viagens e dias fora do padrão
  Para saber onde olhar primeiro, sem que nenhum dado seja apagado

  Cenário: Viagem com duração fora do comum é sinalizada e continua na base
    Dado a carga completa nos bancos
    Quando consulto as viagens marcadas como suspeitas
    Então são 4 viagens com o motivo "duração fora do comum"
    E elas continuam na tabela de viagens

  Cenário: O Isolation Forest aponta os dias atípicos de cada linha
    Dado as viagens limpas de 01/07 a 14/09/2026 no PostgreSQL
    Quando o Isolation Forest pontua cada linha em cada dia
    Então cerca de 2% dos registros são marcados como atípicos
    E o resultado vem do mais atípico para o menos atípico
    E cada dia atípico diz qual variável mais destoou

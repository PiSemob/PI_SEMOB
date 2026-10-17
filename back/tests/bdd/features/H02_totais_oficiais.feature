# language: pt
@H02 @RF03
Funcionalidade: Totais iguais aos relatórios oficiais
  Como gestor da SEMOB
  Quero que os totais do sistema sejam os mesmos dos relatórios do Smart Report
  Para confiar nos indicadores que o painel e o assistente mostram

  Esquema do Cenário: Viagens e quilometragem do período batem com o Total Geral
    Dado o relatório Resumo Geral "<relatorio>"
    Quando consulto no PostgreSQL as viagens dos dias desse relatório
    Então o número de viagens realizadas é <viagens>, igual ao Total Geral
    E a quilometragem total bate com o Total Geral do relatório

    Exemplos:
      | relatorio                               | viagens |
      | Julho_2026/Mensal/Mensal_202607.html    | 36330   |
      | Agosto_2026/Mensal/Mensal_202608.html   | 34994   |
      | Agosto_2026/Quinzenal/Quinzenal_202608.html | 16029 |
      | Setembro_2026/Quinzenal/Quinzenal_202609.html | 15489 |

  Cenário: Passageiros de agosto batem com o Total Mês
    Dado o relatório "Agosto_2026/Mensal/Passageiros_Mensal.html"
    Quando somo no PostgreSQL os passageiros de agosto
    Então o total é 1050248, igual ao Total Mês do relatório

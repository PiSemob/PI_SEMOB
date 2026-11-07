import csv
from datetime import date
from pathlib import Path

import pytest

from app.agente import intencao, interpretacao
from app.texto import normalizar

PERGUNTAS = Path(__file__).resolve().parent / "perguntas.csv"
PRIMEIRO, ULTIMO = date(2026, 7, 1), date(2026, 9, 14)


def _perguntas() -> list[dict]:
    with PERGUNTAS.open(encoding="utf-8") as arquivo:
        return list(csv.DictReader(arquivo))


def test_acerta_as_perguntas_de_teste():
    perguntas = _perguntas()
    assert len(perguntas) >= 40
    erros = [p["pergunta"] for p in perguntas if intencao.decidir(p["pergunta"]).opcao != p["opcao_esperada"]]
    assert erros == []


def test_opcoes_do_csv_existem():
    assert {p["opcao_esperada"] for p in _perguntas()} <= set(intencao.OPCOES)


@pytest.mark.parametrize(
    "frase, esperado",
    [
        ("em agosto", (date(2026, 8, 1), date(2026, 8, 31))),
        ("em setembro", (date(2026, 9, 1), date(2026, 9, 14))),
        ("de julho a agosto", (date(2026, 7, 1), date(2026, 8, 31))),
        ("na última semana", (date(2026, 9, 8), date(2026, 9, 14))),
        ("no último mês", (date(2026, 8, 16), date(2026, 9, 14))),
        ("nos últimos 10 dias", (date(2026, 9, 5), date(2026, 9, 14))),
        ("ontem", (date(2026, 9, 14), date(2026, 9, 14))),
        ("de 01/08 a 07/08", (date(2026, 8, 1), date(2026, 8, 7))),
        ("em 03/09/2026", (date(2026, 9, 3), date(2026, 9, 3))),
        ("qual linha fez mais viagens", None),
    ],
)
def test_periodo_da_frase(frase, esperado):
    assert interpretacao.extrair_periodo(normalizar(frase), PRIMEIRO, ULTIMO) == esperado


@pytest.mark.parametrize("frase, linha", [("linha 4", "04"), ("na linha 10", "10"), ("linha nº 3", "03"), ("sistema", None)])
def test_linha_da_frase(frase, linha):
    assert interpretacao.extrair_linha(normalizar(frase)) == linha


@pytest.mark.parametrize(
    "frase, ferramenta",
    [
        ("Qual linha fez mais viagens em agosto?", "viagens_por_linha"),
        ("Quantos passageiros não pagantes na última semana?", "passageiros_por_dia"),
        ("Em que horário a frota tem mais partidas?", "partidas_por_faixa_horaria"),
        ("Quais viagens não foram realizadas em setembro?", "viagens_com_problema"),
        ("Como estão as vendas de créditos?", "creditos"),
        ("Qual foi o cumprimento do último mês?", "resumo_operacao"),
        ("Até quando vão os dados?", "sobre_os_dados"),
    ],
)
def test_consulta_escolhe_a_ferramenta(frase, ferramenta):
    assert interpretacao.interpretar("consulta", frase, PRIMEIRO, ULTIMO).ferramenta == ferramenta


def test_comparacao_entre_dois_meses():
    pedido = interpretacao.interpretar("comparacao", "compare agosto com julho", PRIMEIRO, ULTIMO)
    assert pedido.argumentos == {"inicio_a": "2026-07-01", "fim_a": "2026-07-31",
                                 "inicio_b": "2026-08-01", "fim_b": "2026-08-31"}


def test_comparacao_com_um_mes_usa_o_mes_anterior():
    pedido = interpretacao.interpretar("comparacao", "os passageiros cresceram em agosto?", PRIMEIRO, ULTIMO)
    assert pedido.argumentos == {"inicio_a": "2026-07-01", "fim_a": "2026-07-31",
                                 "inicio_b": "2026-08-01", "fim_b": "2026-08-31"}


def test_comparacao_sem_periodo_usa_os_30_dias_anteriores():
    pedido = interpretacao.interpretar("comparacao", "a operação melhorou?", PRIMEIRO, ULTIMO)
    assert pedido.argumentos == {"inicio_a": "2026-07-17", "fim_a": "2026-08-15",
                                 "inicio_b": "2026-08-16", "fim_b": "2026-09-14"}


def test_previsao_de_passageiros_ignora_a_linha():
    pedido = interpretacao.interpretar("previsao", "passageiros da linha 04 amanhã", PRIMEIRO, ULTIMO)
    assert pedido.argumentos == {"alvo": "passageiros", "dias": 1}


def test_sem_periodo_usa_os_ultimos_30_dias():
    pedido = interpretacao.interpretar("consulta", "qual o cumprimento?", PRIMEIRO, ULTIMO)
    assert pedido.argumentos == {"inicio": "2026-08-16", "fim": "2026-09-14"}
    assert not pedido.periodo_explicito


def test_viagens_nao_realizadas_filtram_a_situacao():
    pedido = interpretacao.interpretar("consulta", "viagens não realizadas em agosto", PRIMEIRO, ULTIMO)
    assert pedido.argumentos["situacao"] == "nao_realizada"


def test_seguimento_troca_so_o_periodo():
    pedido = interpretacao.seguimento("E em setembro?", "Qual linha fez mais viagens em agosto?", "consulta",
                                      PRIMEIRO, ULTIMO)
    assert pedido.ferramenta == "viagens_por_linha"
    assert pedido.argumentos == {"inicio": "2026-09-01", "fim": "2026-09-14"}


def test_seguimento_sem_periodo_nem_linha_nao_continua():
    assert interpretacao.seguimento("E daí?", "Qual linha fez mais viagens?", "consulta", PRIMEIRO, ULTIMO) is None

"""Aceitação: o que ficou gravado nos bancos bate com os totais impressos nos HTMLs originais.

Os valores esperados saem da linha "Total Geral" / "Total Mês" de cada relatório do
Smart Report, convertidos aqui mesmo (tests/apoio.py), sem passar pela limpeza do app.
Os valores conferidos saem de consultas aos bancos de teste depois do `ingerir`.
"""

from collections import defaultdict
from datetime import date

import pytest
from sqlalchemy import func, select

from app.db import tabelas
from app.etl.parsers.leitura import ler_arquivo
from tests.apoio import (
    ARQUIVOS_PASSAGEIROS,
    ARQUIVOS_RESUMO_GERAL,
    BRUTOS,
    inteiro_br,
    resumo_geral_do_html,
)

TODOS_OS_HTML = sorted(BRUTOS.rglob("*.html"))


def nome(caminho):
    return caminho.relative_to(BRUTOS).as_posix()


@pytest.mark.parametrize("caminho", ARQUIVOS_RESUMO_GERAL, ids=nome)
def test_viagens_e_km_no_postgres_batem_com_o_total_geral(carga, caminho):
    html = resumo_geral_do_html(caminho)
    viagens, improdutivas, resumo = tabelas.viagens, tabelas.viagens_improdutivas, tabelas.resumo_geral
    with carga.engine.connect() as conexao:
        realizadas, km_viagens, km_prod_viagens = conexao.execute(
            select(func.count(), func.sum(viagens.c.km_total), func.sum(viagens.c.km_prod))
            .where(viagens.c.data.in_(html.datas))
        ).one()
        km_improdutivo, km_prod_improdutivas = conexao.execute(
            select(func.sum(improdutivas.c.km_total), func.sum(improdutivas.c.km_prod))
            .where(improdutivas.c.data.in_(html.datas))
        ).one()
        programadas = conexao.scalar(
            select(func.sum(resumo.c.nr_viagens_progr)).where(resumo.c.data.in_(html.datas))
        )

    assert realizadas == html.viagens_realizadas
    assert programadas == html.viagens_programadas
    assert float(km_viagens + km_improdutivo) == pytest.approx(html.km_total, abs=0.5)
    assert float(km_prod_viagens + km_prod_improdutivas) == pytest.approx(html.km_prod, abs=0.5)


@pytest.mark.parametrize("caminho", ARQUIVOS_PASSAGEIROS, ids=nome)
def test_passageiros_no_postgres_batem_com_o_total_do_mes(carga, caminho):
    (relatorio,) = ler_arquivo(caminho)
    tabela = relatorio.tabela
    dias_por_mes = defaultdict(list)
    totais_html = {}
    for linha in tabela.to_dict("records"):
        mes, dia = linha["Mês"], linha["Dia"]
        if dia.isdigit():
            ano, numero_mes = mes.split("-")
            dias_por_mes[mes].append(date(int(ano), int(numero_mes), int(dia)))
        elif dia == "Total Mês":
            totais_html[mes] = {
                "catraca": inteiro_br(linha["Catraca"]),
                "antecipados": inteiro_br(linha["Antecipados"]),
                "nao_pagantes": inteiro_br(linha["Não Pagantes"]),
                "total": inteiro_br(linha["Total Passageiros"]),
            }
    assert totais_html, "relatório sem linha de Total Mês"

    t = tabelas.passageiros
    with carga.engine.connect() as conexao:
        for mes, esperado in totais_html.items():
            soma = conexao.execute(
                select(*(func.sum(t.c[coluna]) for coluna in esperado))
                .where(t.c.data.in_(dias_por_mes[mes]))
            ).one()
            assert dict(zip(esperado, soma)) == esperado, mes


def test_agosto_tem_1050248_passageiros_no_postgres(carga):
    t = tabelas.passageiros
    with carga.engine.connect() as conexao:
        total = conexao.scalar(
            select(func.sum(t.c.total)).where(t.c.data.between(date(2026, 8, 1), date(2026, 8, 31)))
        )
    assert total == 1050248


@pytest.mark.parametrize("caminho", TODOS_OS_HTML, ids=nome)
def test_mongo_guarda_todas_as_linhas_de_cada_html(carga, caminho):
    """No bruto nada é descartado: cada linha do HTML, inclusive as de total, vira documento."""
    linhas_no_html = sum(len(relatorio.tabela) for relatorio in ler_arquivo(caminho))
    colecoes = carga.mongo.list_collection_names()
    no_mongo = sum(
        carga.mongo[colecao].count_documents({"arquivo_origem": nome(caminho)})
        for colecao in colecoes
    )
    assert no_mongo == linhas_no_html

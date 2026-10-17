"""Passos dos cenários BDD (tests/bdd/features/*.feature), rodando contra os bancos reais.

Cada arquivo .feature é uma história (H01...H04) e leva as marcas dos requisitos que
cobre (@RF01...). Para rodar só uma: `pytest tests/bdd -m H02`.
"""

from datetime import date

import pytest
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers, scenarios, then, when
from sqlalchemy import func, select

from app.db import postgres, tabelas
from app.main import app
from app.ml import dados
from app.ml.fiscalizacao import isolation_forest
from tests.apoio import BRUTOS, ResumoGeralHtml, inteiro_br, resumo_geral_do_html

scenarios("")


@pytest.fixture
def contexto() -> dict:
    """O que um passo deixa para os passos seguintes do mesmo cenário."""
    return {}


# ---------------------------------------------------------------- H01: carga


@given("os 44 relatórios HTML em dados/brutos")
def relatorios_brutos():
    assert len(list(BRUTOS.rglob("*.html"))) == 44


@when("o script ingerir roda nos bancos vazios")
@given("que o script ingerir já rodou uma vez")
def ingerir_uma_vez(carga):
    assert "Etapa 2 (limpo):" in carga.saidas[0]


@when("o script ingerir roda de novo")
def ingerir_de_novo(carga):
    assert len(carga.saidas) == 2


@then(parsers.parse("o MongoDB guarda {quantidade:d} viagens brutas"))
def mongo_guarda(carga, quantidade):
    assert carga.mongo["viagens"].count_documents({}) == quantidade


@then(parsers.parse("o PostgreSQL guarda {quantidade:d} viagens limpas"))
def postgres_guarda(carga, quantidade):
    with carga.engine.connect() as conexao:
        assert conexao.scalar(select(func.count()).select_from(tabelas.viagens)) == quantidade


@then("todo registro limpo aponta para o HTML de onde veio")
def registros_com_origem(carga):
    with carga.engine.connect() as conexao:
        for tabela in tabelas.metadata.tables.values():
            for origem in conexao.scalars(select(tabela.c.arquivo_origem).distinct()):
                assert (BRUTOS / origem).is_file(), origem


@then("nenhuma coleção nem tabela muda de tamanho")
def nada_duplicou(carga):
    assert carga.contagens[1] == carga.contagens[0]


# ------------------------------------------------------- H02: totais oficiais


@given(parsers.parse('o relatório Resumo Geral "{relatorio}"'))
def relatorio_resumo_geral(contexto, relatorio):
    contexto["html"] = resumo_geral_do_html(BRUTOS / relatorio)


@when("consulto no PostgreSQL as viagens dos dias desse relatório")
def consultar_viagens_do_relatorio(carga, contexto):
    html: ResumoGeralHtml = contexto["html"]
    v, i = tabelas.viagens, tabelas.viagens_improdutivas
    with carga.engine.connect() as conexao:
        contexto["viagens"], km_viagens = conexao.execute(
            select(func.count(), func.sum(v.c.km_total)).where(v.c.data.in_(html.datas))
        ).one()
        km_improdutivo = conexao.scalar(
            select(func.sum(i.c.km_total)).where(i.c.data.in_(html.datas))
        )
    contexto["km_total"] = float(km_viagens + km_improdutivo)


@then(parsers.parse("o número de viagens realizadas é {viagens:d}, igual ao Total Geral"))
def viagens_iguais(contexto, viagens):
    assert contexto["viagens"] == viagens == contexto["html"].viagens_realizadas


@then("a quilometragem total bate com o Total Geral do relatório")
def km_igual(contexto):
    assert contexto["km_total"] == pytest.approx(contexto["html"].km_total, abs=0.5)


@given(parsers.parse('o relatório "{relatorio}"'))
def relatorio_passageiros(contexto, relatorio):
    from app.etl.parsers.leitura import ler_arquivo

    (lido,) = ler_arquivo(BRUTOS / relatorio)
    (total,) = lido.tabela[lido.tabela["Dia"] == "Total Mês"].to_dict("records")
    contexto["total_html"] = inteiro_br(total["Total Passageiros"])


@when("somo no PostgreSQL os passageiros de agosto")
def somar_passageiros(carga, contexto):
    p = tabelas.passageiros
    with carga.engine.connect() as conexao:
        contexto["total_banco"] = conexao.scalar(
            select(func.sum(p.c.total)).where(p.c.data.between(date(2026, 8, 1), date(2026, 8, 31)))
        )


@then(parsers.parse("o total é {total:d}, igual ao Total Mês do relatório"))
def passageiros_iguais(contexto, total):
    assert contexto["total_banco"] == total == contexto["total_html"]


# ------------------------------------------------- H03: suspeitos e anomalias


@given("a carga completa nos bancos")
def carga_completa(carga):
    assert carga.contagens


@when("consulto as viagens marcadas como suspeitas")
def consultar_suspeitas(carga, contexto):
    v = tabelas.viagens
    with carga.engine.connect() as conexao:
        contexto["suspeitas"] = conexao.execute(select(v).where(v.c.suspeito)).mappings().all()
        contexto["total_viagens"] = conexao.scalar(select(func.count()).select_from(v))


@then(parsers.parse('são {quantidade:d} viagens com o motivo "{motivo}"'))
def suspeitas_com_motivo(contexto, quantidade, motivo):
    assert len(contexto["suspeitas"]) == quantidade
    assert {linha["motivo_suspeita"] for linha in contexto["suspeitas"]} == {motivo}


@then("elas continuam na tabela de viagens")
def suspeitas_nao_apagadas(contexto):
    assert contexto["total_viagens"] == 86813


@given("as viagens limpas de 01/07 a 14/09/2026 no PostgreSQL")
def viagens_do_periodo(carga, contexto, monkeypatch):
    monkeypatch.setattr(postgres, "criar_engine", lambda: carga.engine)
    contexto["viagens"] = dados.ler_viagens(date(2026, 7, 1), date(2026, 9, 14))
    assert len(contexto["viagens"]) == 86813


@when("o Isolation Forest pontua cada linha em cada dia")
def pontuar(contexto):
    contexto["resultado"] = isolation_forest.pontuar(dados.agregar_linha_dia(contexto["viagens"]))


@then("cerca de 2% dos registros são marcados como atípicos")
def dois_por_cento(contexto):
    proporcao = contexto["resultado"]["atipico"].mean()
    assert proporcao == pytest.approx(isolation_forest.CONTAMINACAO, abs=0.01)


@then("o resultado vem do mais atípico para o menos atípico")
def ordenado(contexto):
    assert contexto["resultado"]["pontuacao"].is_monotonic_decreasing


@then("cada dia atípico diz qual variável mais destoou")
def destaque(contexto):
    atipicos = contexto["resultado"][contexto["resultado"]["atipico"]]
    assert not atipicos.empty
    for texto in atipicos["destaque"]:
        assert texto.split(":")[0] in isolation_forest.VARIAVEIS
        assert "desvios" in texto


# -------------------------------------------------------------- H04: API no ar


@given("a API do back", target_fixture="cliente")
def api():
    return TestClient(app)


@when("o app chama GET /saude")
def chamar_saude(cliente, contexto):
    contexto["resposta"] = cliente.get("/saude")


@then('a resposta tem status 200 e o corpo {"status": "ok"}')
def saude_ok(contexto):
    assert contexto["resposta"].status_code == 200
    assert contexto["resposta"].json() == {"status": "ok"}

"""Teste de sistema: `criar_tabelas` + `ingerir` de ponta a ponta, nos containers reais.

A fixture `carga` (tests/conftest.py) zera os bancos de teste, roda os dois scripts
como um usuário rodaria (`python -m scripts...`) e roda o `ingerir` uma segunda vez.
"""

from sqlalchemy import distinct, func, select

from app.db import tabelas
from tests.apoio import BRUTOS

# Contagem conferida na carga de 15/10/2026 (ver docs/testes.md).
ESPERADO_POSTGRES = {
    "viagens": 86813,
    "viagens_improdutivas": 4295,
    "viagens_excecao": 122,
    "resumo_geral": 76,
    "resumo_linha": 698,
    "partidas_faixa_horaria": 14006,
    "resumo_faixa_horaria": 1596,
    "fcv": 76,
    "passageiros": 62,
    "saldos": 52,
    "vendas": 71,
}
ESPERADO_MONGO = {
    "viagens": 107931,
    "viagens_nao_iniciadas": 15,
    "viagens_nao_realizadas": 125,
    "viagens_nao_terminadas": 21,
    "resumo_geral": 94,
    "resumo_linha": 828,
    "partidas_faixa_horaria": 16541,
    "resumo_faixa_horaria": 1894,
    "fcv": 94,
    "passageiros": 83,
    "saldos": 71,
    "vendas": 96,
}


def test_ingerir_le_os_44_arquivos_sem_aviso(carga, record_property):
    saida = carga.saidas[0]
    record_property("segundos_primeira_carga", round(carga.segundos[0], 1))
    assert "Etapa 1 (bruto): 44 arquivos" in saida
    assert "Etapa 2 (limpo):" in saida
    assert "AVISO" not in saida


def test_postgres_recebe_as_86813_viagens(carga):
    assert carga.contagens[0]["postgres"]["viagens"] == 86813


def test_postgres_tem_todas_as_tabelas_com_o_volume_esperado(carga):
    assert carga.contagens[0]["postgres"] == ESPERADO_POSTGRES


def test_mongo_guarda_o_bruto_completo(carga):
    assert carga.contagens[0]["mongo"] == ESPERADO_MONGO


def test_rodar_o_ingerir_de_novo_nao_duplica_nada(carga, record_property):
    record_property("segundos_segunda_carga", round(carga.segundos[1], 1))
    assert carga.contagens[1] == carga.contagens[0]


def test_todo_registro_limpo_aponta_para_um_html_que_existe(carga):
    with carga.engine.connect() as conexao:
        for nome, tabela in tabelas.metadata.tables.items():
            sem_origem = conexao.scalar(
                select(func.count()).where(tabela.c.arquivo_origem.is_(None))
            )
            assert sem_origem == 0, nome
            origens = conexao.scalars(select(distinct(tabela.c.arquivo_origem))).all()
            for origem in origens:
                assert (BRUTOS / origem).is_file(), f"{nome}: {origem}"


def test_viagens_cobrem_de_1_de_julho_a_14_de_setembro(carga):
    with carga.engine.connect() as conexao:
        inicio, fim = conexao.execute(
            select(func.min(tabelas.viagens.c.data), func.max(tabelas.viagens.c.data))
        ).one()
    assert (inicio.isoformat(), fim.isoformat()) == ("2026-07-01", "2026-09-14")

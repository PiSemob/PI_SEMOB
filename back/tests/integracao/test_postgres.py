"""Integração com o container do PostgreSQL (camada limpa), usando os dados reais limpos."""

from datetime import date, datetime
from decimal import Decimal

import pytest
from sqlalchemy import func, insert, inspect, select
from sqlalchemy.exc import IntegrityError

import app.db.postgres
from app.db import tabelas
from app.db.tabelas import metadata
from app.etl.limpeza import gravar
from app.ml import dados
from tests.apoio import BANCO_INTEGRACAO, recriar_postgres


@pytest.fixture(scope="module")
def engine(bancos_no_ar, limpas):
    """Banco de integração com as 11 tabelas criadas e os dados limpos gravados uma vez."""
    engine = recriar_postgres(BANCO_INTEGRACAO)
    metadata.create_all(engine)
    with engine.begin() as conexao:
        for nome, df in limpas.items():
            gravar(conexao, metadata.tables[nome], df)
    yield engine
    engine.dispose()


def contagem(engine, tabela):
    with engine.connect() as conexao:
        return conexao.scalar(select(func.count()).select_from(tabela))


def test_as_11_tabelas_existem_com_chave_primaria(engine):
    inspetor = inspect(engine)
    assert set(inspetor.get_table_names()) == set(metadata.tables)
    for nome in metadata.tables:
        assert inspetor.get_pk_constraint(nome)["constrained_columns"], nome


def test_cada_tabela_tem_o_que_a_limpeza_produziu(engine, limpas):
    for nome, df in limpas.items():
        assert contagem(engine, metadata.tables[nome]) == len(df), nome


def test_gravar_de_novo_no_postgres_nao_duplica(engine, limpas):
    # Regrava tudo, menos as viagens, que entram só com uma amostra de 3.000: o
    # "inserir ou atualizar" é o mesmo e a regravação completa leva minutos.
    with engine.begin() as conexao:
        for nome, df in limpas.items():
            gravar(conexao, metadata.tables[nome], df.head(3000) if nome == "viagens" else df)
    for nome, df in limpas.items():
        assert contagem(engine, metadata.tables[nome]) == len(df), nome


def test_chave_primaria_barra_insercao_repetida(engine):
    with engine.connect() as conexao:
        linha = conexao.execute(select(tabelas.viagens).limit(1)).mappings().one()
    with pytest.raises(IntegrityError), engine.begin() as conexao:
        conexao.execute(insert(tabelas.viagens).values(**linha))


def test_quilometragem_e_guardada_sem_erro_de_arredondamento(engine, limpas):
    esperado = sum(Decimal(f"{km:.2f}") for km in limpas["viagens"]["km_total"])
    with engine.connect() as conexao:
        no_banco = conexao.scalar(select(func.sum(tabelas.viagens.c.km_total)))
    assert isinstance(no_banco, Decimal)
    assert no_banco == esperado


def test_datas_chegam_como_data_e_hora(engine):
    with engine.connect() as conexao:
        linha = conexao.execute(select(tabelas.viagens).limit(1)).mappings().one()
    assert type(linha["data"]) is date
    assert isinstance(linha["inicio_realizado"], datetime)
    assert isinstance(linha["gerado_em"], datetime)


def test_camada_de_ml_le_do_postgres(engine, monkeypatch):
    monkeypatch.setattr(app.db.postgres, "criar_engine", lambda: engine)

    agosto = dados.ler_viagens(date(2026, 8, 1), date(2026, 8, 31))
    assert len(agosto) == 34994
    assert len(dados.ler_viagens(date(2026, 8, 1), date(2026, 8, 31), linha="01")) > 0

    passageiros = dados.ler_serie("passageiros")
    assert len(passageiros) == 62
    assert list(passageiros.columns) == ["ds", "y"]

    assert "01" in dados.ler_linhas(minimo_de_dias=30)

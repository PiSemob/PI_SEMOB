from datetime import date, datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

from app.api.dependencias import obter_conexao
from app.db import tabelas
from app.main import app

ORIGEM = {"arquivo_origem": "teste.html", "gerado_em": datetime(2026, 9, 4, 8, 0)}
PERIODO = {"inicio": "2026-08-01", "fim": "2026-08-03"}


@pytest.fixture
def cliente():
    """Cliente da API ligado a um banco SQLite em memória, com três dias de dados."""
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    tabelas.metadata.create_all(engine)
    with engine.begin() as conexao:
        conexao.execute(
            tabelas.resumo_geral.insert(),
            [
                {"data": date(2026, 8, 1), "dia_sem": "Sab", "nr_veiculos": 37,
                 "nr_viagens_progr": 100, "nr_viagens_realiz": 100, "km_prod": 700,
                 "km_improd": 50, "km_total": 750, **ORIGEM},
                {"data": date(2026, 8, 2), "dia_sem": "Dom", "nr_veiculos": 25,
                 "nr_viagens_progr": 80, "nr_viagens_realiz": 76, "km_prod": 500,
                 "km_improd": 50, "km_total": 550, **ORIGEM},
                {"data": date(2026, 8, 3), "dia_sem": "Seg", "nr_veiculos": 53,
                 "nr_viagens_progr": 120, "nr_viagens_realiz": 114, "km_prod": 900,
                 "km_improd": 100, "km_total": 1000, **ORIGEM},
            ],
        )
        conexao.execute(
            tabelas.passageiros.insert(),
            [
                {"data": date(2026, 8, 2), "catraca": 100, "antecipados": 50,
                 "nao_pagantes": 250, "total": 400, **ORIGEM},
                {"data": date(2026, 8, 3), "catraca": 300, "antecipados": 100,
                 "nao_pagantes": 750, "total": 1150, **ORIGEM},
            ],
        )

    def conexao_de_teste():
        with engine.connect() as conexao:
            yield conexao

    app.dependency_overrides[obter_conexao] = conexao_de_teste
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.mark.filterwarnings("ignore::sqlalchemy.exc.SAWarning")
def test_resumo_soma_o_periodo(cliente):
    resposta = cliente.get("/indicadores/resumo", params=PERIODO)
    assert resposta.status_code == 200
    corpo = resposta.json()
    assert corpo["dias_com_operacao"] == 3
    assert corpo["viagens_programadas"] == 300
    assert corpo["viagens_realizadas"] == 290
    assert corpo["cumprimento"] == pytest.approx(0.9667)
    assert corpo["km_total"] == 2300
    assert corpo["passageiros"] == 1550
    assert corpo["dias_com_passageiros"] == 2
    assert corpo["ipk"] == 1.0
    assert corpo["parcela_nao_pagantes"] == pytest.approx(0.6452)


@pytest.mark.filterwarnings("ignore::sqlalchemy.exc.SAWarning")
def test_resumo_de_periodo_sem_dados_nao_da_erro(cliente):
    corpo = cliente.get("/indicadores/resumo", params={"inicio": "2025-01-01", "fim": "2025-01-31"}).json()
    assert corpo["viagens_realizadas"] == 0
    assert corpo["cumprimento"] is None
    assert corpo["ipk"] is None


def test_inicio_depois_do_fim_e_recusado(cliente):
    resposta = cliente.get("/indicadores/resumo", params={"inicio": "2026-08-03", "fim": "2026-08-01"})
    assert resposta.status_code == 400


def test_data_invalida_e_recusada(cliente):
    resposta = cliente.get("/indicadores/resumo", params={"inicio": "ontem", "fim": "2026-08-01"})
    assert resposta.status_code == 422


def test_periodo_disponivel(cliente):
    corpo = cliente.get("/indicadores/periodo").json()
    assert corpo["operacao"] == {"inicio": "2026-08-01", "fim": "2026-08-03"}
    assert corpo["passageiros"] == {"inicio": "2026-08-02", "fim": "2026-08-03"}

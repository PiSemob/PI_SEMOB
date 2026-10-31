"""Testa a rota de anomalias com modelos falsos.

O que se confere aqui é a rota: os parâmetros, o formato da resposta e os erros.
Os modelos de verdade têm os próprios testes em tests/ml.
"""

from datetime import date

import pandas as pd
from fastapi.testclient import TestClient

from app.api import anomalias
from app.main import app

cliente = TestClient(app)
PERIODO = {"inicio": "2026-08-01", "fim": "2026-08-31"}


def test_anomalias_do_isolation_forest(monkeypatch):
    chamadas = []

    def falso(inicio, fim, linha):
        chamadas.append((inicio, fim, linha))
        return pd.DataFrame(
            {
                "data": pd.to_datetime(["2026-08-04"]),
                "linha": ["04"],
                "nr_viagens": [116],
                "pontuacao": [0.71],
                "atipico": [True],
                "destaque": ["nr_viagens: 4.0 desvios abaixo do normal"],
            }
        )

    monkeypatch.setattr(anomalias.isolation_forest, "dias_atipicos", falso)
    resposta = cliente.get("/anomalias", params={"modelo": "isolation_forest", "linha": "04", **PERIODO})

    assert resposta.status_code == 200
    assert chamadas == [(date(2026, 8, 1), date(2026, 8, 31), "04")]
    corpo = resposta.json()
    assert corpo["quantidade"] == 1
    assert corpo["anomalias"][0]["data"] == "2026-08-04"
    assert corpo["anomalias"][0]["destaque"].startswith("nr_viagens")


def test_isolation_forest_sem_linha_analisa_todas(monkeypatch):
    chamadas = []
    monkeypatch.setattr(
        anomalias.isolation_forest,
        "dias_atipicos",
        lambda inicio, fim, linha: chamadas.append(linha) or pd.DataFrame(),
    )
    corpo = cliente.get("/anomalias", params={"modelo": "isolation_forest", **PERIODO}).json()
    assert chamadas == [None]
    assert corpo["quantidade"] == 0
    assert corpo["anomalias"] == []


def test_anomalias_do_dbscan_mantem_o_horario(monkeypatch):
    monkeypatch.setattr(
        anomalias.dbscan,
        "viagens_atipicas",
        lambda inicio, fim, linha: pd.DataFrame(
            {
                "inicio_realizado": pd.to_datetime(["2026-08-03 18:44:26"]),
                "duracao_min": [23.6],
                "prefixo": [None],
            }
        ),
    )
    corpo = cliente.get("/anomalias", params={"modelo": "dbscan", "linha": "04", **PERIODO}).json()
    assert corpo["anomalias"] == [
        {"inicio_realizado": "2026-08-03T18:44:26", "duracao_min": 23.6, "prefixo": None}
    ]


def test_dbscan_sem_linha_e_recusado():
    resposta = cliente.get("/anomalias", params={"modelo": "dbscan", **PERIODO})
    assert resposta.status_code == 400
    assert "linha" in resposta.json()["detail"]


def test_modelo_desconhecido_e_recusado():
    resposta = cliente.get("/anomalias", params={"modelo": "outro", **PERIODO})
    assert resposta.status_code == 422


def test_inicio_depois_do_fim_e_recusado():
    resposta = cliente.get(
        "/anomalias", params={"modelo": "isolation_forest", "inicio": "2026-08-31", "fim": "2026-08-01"}
    )
    assert resposta.status_code == 400


def test_erro_do_modelo_vira_400(monkeypatch):
    def falso(inicio, fim, linha):
        raise ValueError("Nenhuma linha com pelo menos 30 dias de operação.")

    monkeypatch.setattr(anomalias.isolation_forest, "dias_atipicos", falso)
    resposta = cliente.get("/anomalias", params={"modelo": "isolation_forest", **PERIODO})
    assert resposta.status_code == 400
    assert "30 dias" in resposta.json()["detail"]

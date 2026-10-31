"""Testa a rota de previsões com um modelo falso.

O que se confere aqui é a rota: os parâmetros, o formato da resposta e os erros.
Os modelos de verdade têm os próprios testes em tests/ml.
"""

import pytest
from fastapi.testclient import TestClient

from app.api import previsoes
from app.main import app

cliente = TestClient(app)


def test_previsao_repassa_os_parametros(monkeypatch):
    chamadas = []

    def falso(alvo, dias, linha):
        chamadas.append((alvo, dias, linha))
        return {"serie": alvo, "linha": linha, "modelo": "sarimax", "previsao": []}

    monkeypatch.setattr(previsoes.previsao, "prever", falso)
    resposta = cliente.get("/previsoes", params={"alvo": "viagens", "linha": "04", "dias": 10})
    assert resposta.status_code == 200
    assert chamadas == [("viagens", 10, "04")]
    assert resposta.json()["modelo"] == "sarimax"


def test_previsao_usa_7_dias_por_padrao(monkeypatch):
    chamadas = []
    monkeypatch.setattr(
        previsoes.previsao, "prever", lambda alvo, dias, linha: chamadas.append(dias) or {}
    )
    cliente.get("/previsoes", params={"alvo": "passageiros"})
    assert chamadas == [7]


@pytest.mark.parametrize("dias", [0, 15])
def test_previsao_fora_de_1_a_14_dias_e_recusada(dias):
    resposta = cliente.get("/previsoes", params={"alvo": "km", "dias": dias})
    assert resposta.status_code == 422


def test_alvo_desconhecido_e_recusado():
    resposta = cliente.get("/previsoes", params={"alvo": "receita"})
    assert resposta.status_code == 422


def test_passageiros_por_linha_vira_400(monkeypatch):
    def falso(alvo, dias, linha):
        raise ValueError("A base só tem passageiros do sistema inteiro, não por linha.")

    monkeypatch.setattr(previsoes.previsao, "prever", falso)
    resposta = cliente.get("/previsoes", params={"alvo": "passageiros", "linha": "04"})
    assert resposta.status_code == 400
    assert "por linha" in resposta.json()["detail"]

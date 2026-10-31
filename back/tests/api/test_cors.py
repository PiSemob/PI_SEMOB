import pytest
from fastapi.testclient import TestClient

from app.main import app

cliente = TestClient(app)


@pytest.mark.parametrize("origem", ["http://localhost:5000", "http://127.0.0.1:61234", "http://localhost"])
def test_cors_libera_o_flutter_web_local(origem):
    resposta = cliente.get("/saude", headers={"Origin": origem})
    assert resposta.headers["access-control-allow-origin"] == origem


def test_cors_nao_libera_outro_site():
    resposta = cliente.get("/saude", headers={"Origin": "http://exemplo.com"})
    assert "access-control-allow-origin" not in resposta.headers


def test_navegador_pode_perguntar_antes_de_chamar():
    resposta = cliente.options(
        "/indicadores/resumo",
        headers={"Origin": "http://localhost:5000", "Access-Control-Request-Method": "GET"},
    )
    assert resposta.status_code == 200
    assert resposta.headers["access-control-allow-origin"] == "http://localhost:5000"

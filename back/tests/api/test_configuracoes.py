import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

from app.api.dependencias import obter_conexao, usuario_atual
from app.autenticacao import Usuario
from app.db.tabelas_app import metadata_app
from app.main import app


@pytest.fixture
def cliente():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    metadata_app.create_all(engine)

    def conexao_de_teste():
        with engine.connect() as conexao:
            yield conexao

    app.dependency_overrides[obter_conexao] = conexao_de_teste
    app.dependency_overrides[usuario_atual] = lambda: Usuario(1, "gestor@semob.sp.gov.br", "Gestora")
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_sem_nada_salvo_devolve_o_padrao(cliente):
    assert cliente.get("/configuracoes").json() == {
        "organizacao": "SEMOB-SCS",
        "cidade": "São Caetano do Sul",
        "alertas_anomalia": True,
        "relatorios_automaticos": False,
        "email_relatorios": "",
    }


def test_salva_so_o_que_foi_enviado(cliente):
    corpo = cliente.put("/configuracoes", json={"cidade": "Santo André", "alertas_anomalia": False}).json()
    assert corpo["cidade"] == "Santo André"
    assert corpo["alertas_anomalia"] is False
    assert corpo["organizacao"] == "SEMOB-SCS"
    assert cliente.get("/configuracoes").json()["cidade"] == "Santo André"


def test_campos_tecnicos_nao_sao_aceitos(cliente):
    cliente.put("/configuracoes", json={"here_api_key": "x", "retencao_dias": 7})
    assert "here_api_key" not in cliente.get("/configuracoes").json()


@pytest.mark.parametrize("mudanca", [{"organizacao": "  "}, {"email_relatorios": "sem-arroba"}])
def test_valores_invalidos_sao_recusados(cliente, mudanca):
    resposta = cliente.put("/configuracoes", json=mudanca)
    assert resposta.status_code == 400
    assert resposta.json()["detail"]

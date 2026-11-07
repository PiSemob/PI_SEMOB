import re

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

from app import autenticacao
from app.api.dependencias import obter_conexao
from app.db.tabelas_app import metadata_app
from app.main import app

EMAIL, SENHA = "gestor@semob.sp.gov.br", "senha-forte-1"


@pytest.fixture
def engine():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    metadata_app.create_all(engine)
    with engine.connect() as conexao:
        autenticacao.criar_usuario(conexao, EMAIL, "Gestora", SENHA)
    return engine


@pytest.fixture
def emails(monkeypatch):
    enviados = []
    monkeypatch.setattr(autenticacao, "enviar_email", lambda para, assunto, texto, anexos=None: enviados.append((para, texto)))
    return enviados


@pytest.fixture
def cliente(engine, emails):
    def conexao_de_teste():
        with engine.connect() as conexao:
            yield conexao

    app.dependency_overrides[obter_conexao] = conexao_de_teste
    yield TestClient(app)
    app.dependency_overrides.clear()


def _entrar(cliente, senha=SENHA):
    return cliente.post("/auth/login", json={"email": EMAIL, "senha": senha})


def test_senha_guardada_como_hash():
    guardado = autenticacao.gerar_hash("minha-senha")
    assert "minha-senha" not in guardado
    assert autenticacao.conferir_senha("minha-senha", guardado)
    assert not autenticacao.conferir_senha("outra", guardado)


def test_login_devolve_token_e_usuario(cliente):
    resposta = _entrar(cliente)
    assert resposta.status_code == 200
    assert resposta.json()["usuario"] == {"email": EMAIL, "nome": "Gestora", "admin": False}
    token = resposta.json()["token"]
    eu = cliente.get("/auth/eu", headers={"Authorization": f"Bearer {token}"})
    assert eu.json()["email"] == EMAIL


def test_email_com_maiusculas_tambem_entra(cliente):
    resposta = cliente.post("/auth/login", json={"email": " Gestor@SEMOB.sp.gov.br ", "senha": SENHA})
    assert resposta.status_code == 200


def test_senha_errada_e_email_inexistente_dao_a_mesma_mensagem(cliente):
    errada = _entrar(cliente, "errada")
    inexistente = cliente.post("/auth/login", json={"email": "ninguem@x.com", "senha": SENHA})
    assert errada.status_code == inexistente.status_code == 401
    assert errada.json() == inexistente.json()


def test_rotas_protegidas_pedem_login(cliente):
    assert cliente.get("/auth/eu").status_code == 401
    assert cliente.get("/auth/eu", headers={"Authorization": "Bearer inventado"}).status_code == 401
    assert cliente.get("/configuracoes").status_code == 401
    assert cliente.post("/chat", json={"mensagem": "oi"}).status_code == 401


def test_sair_encerra_a_sessao(cliente):
    cabecalho = {"Authorization": f"Bearer {_entrar(cliente).json()['token']}"}
    assert cliente.post("/auth/sair", headers=cabecalho).status_code == 204
    assert cliente.get("/auth/eu", headers=cabecalho).status_code == 401


def test_recuperacao_nao_revela_quem_tem_cadastro(cliente, emails):
    assert cliente.post("/auth/recuperar-senha", json={"email": "ninguem@x.com"}).status_code == 202
    assert emails == []
    assert cliente.post("/auth/recuperar-senha", json={"email": EMAIL}).status_code == 202
    assert len(emails) == 1 and emails[0][0] == EMAIL


def test_fluxo_completo_de_redefinicao(cliente, emails):
    sessao_antiga = {"Authorization": f"Bearer {_entrar(cliente).json()['token']}"}
    cliente.post("/auth/recuperar-senha", json={"email": EMAIL})
    link = re.search(r"http\S+", emails[0][1]).group(0)
    assert "/#/redefinir-senha?token=" in link
    token = link.split("token=")[1]

    curta = cliente.post("/auth/redefinir-senha", json={"token": token, "senha": "123"})
    assert curta.status_code == 400 and "8 caracteres" in curta.json()["detail"]

    assert cliente.post("/auth/redefinir-senha", json={"token": token, "senha": "senha-nova-2"}).status_code == 204
    assert _entrar(cliente, "senha-nova-2").status_code == 200
    assert _entrar(cliente).status_code == 401
    assert cliente.get("/auth/eu", headers=sessao_antiga).status_code == 401
    reuso = cliente.post("/auth/redefinir-senha", json={"token": token, "senha": "senha-nova-3"})
    assert reuso.status_code == 400 and "inválido ou expirou" in reuso.json()["detail"]


def test_link_inventado_e_recusado(cliente):
    resposta = cliente.post("/auth/redefinir-senha", json={"token": "x" * 40, "senha": "senha-nova-2"})
    assert resposta.status_code == 400


def test_nao_cria_usuario_repetido(engine):
    with engine.connect() as conexao, pytest.raises(autenticacao.ErroAutenticacao):
        autenticacao.criar_usuario(conexao, EMAIL.upper(), "Outra", "outra-senha")

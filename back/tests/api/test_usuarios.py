import re

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

from app import autenticacao, usuarios
from app.api.dependencias import obter_conexao
from app.db.tabelas_app import metadata_app
from app.main import app

ADMIN, SENHA = "admin@semob.sp.gov.br", "senha-forte-1"
COMUM = "comum@semob.sp.gov.br"
NOVO = "novo@semob.sp.gov.br"


@pytest.fixture
def engine():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    metadata_app.create_all(engine)
    with engine.connect() as conexao:
        autenticacao.criar_usuario(conexao, ADMIN, "Ana Admin", SENHA, admin=True)
        autenticacao.criar_usuario(conexao, COMUM, "Caio Comum", SENHA)
    return engine


@pytest.fixture
def emails(monkeypatch):
    enviados = []

    def guardar(para, assunto, texto, anexos=None):
        enviados.append((para, texto))

    monkeypatch.setattr(autenticacao, "enviar_email", guardar)
    monkeypatch.setattr(usuarios, "enviar_email", guardar)
    return enviados


@pytest.fixture
def cliente(engine, emails):
    def conexao_de_teste():
        with engine.connect() as conexao:
            yield conexao

    app.dependency_overrides[obter_conexao] = conexao_de_teste
    yield TestClient(app)
    app.dependency_overrides.clear()


def _cabecalho(cliente, email=ADMIN, senha=SENHA):
    token = cliente.post("/auth/login", json={"email": email, "senha": senha}).json()["token"]
    return {"Authorization": f"Bearer {token}"}


def _usuario(cliente, cabecalho, email):
    return next(u for u in cliente.get("/usuarios", headers=cabecalho).json() if u["email"] == email)


def _token(texto, rota="criar-senha"):
    link = re.search(r"http\S+", texto).group(0)
    assert f"/#/{rota}?token=" in link
    return link.split("token=")[1]


def _criar_senha(cliente, token, senha="senha-da-nina"):
    return cliente.post("/auth/redefinir-senha", json={"token": token, "senha": senha})


def test_login_informa_quem_e_administrador(cliente):
    resposta = cliente.post("/auth/login", json={"email": ADMIN, "senha": SENHA})
    assert resposta.json()["usuario"]["admin"] is True
    assert cliente.get("/auth/eu", headers=_cabecalho(cliente, COMUM)).json()["admin"] is False


def test_so_administrador_gerencia_usuarios(cliente):
    assert cliente.get("/usuarios").status_code == 401
    comum = _cabecalho(cliente, COMUM)
    assert cliente.get("/usuarios", headers=comum).status_code == 403
    assert cliente.post("/usuarios", headers=comum, json={"email": NOVO, "nome": "Novo"}).status_code == 403
    assert cliente.get("/usuarios", headers=_cabecalho(cliente)).status_code == 200


def test_lista_nao_expoe_senha(cliente):
    lista = cliente.get("/usuarios", headers=_cabecalho(cliente)).json()
    assert {u["email"] for u in lista} == {ADMIN, COMUM}
    assert all("senha_hash" not in u and u["pendente"] is False for u in lista)


def test_convite_completo(cliente, emails):
    admin = _cabecalho(cliente)
    resposta = cliente.post("/usuarios", headers=admin, json={"email": " Novo@SEMOB.sp.gov.br ", "nome": "Nina"})
    assert resposta.status_code == 201
    assert resposta.json()["email"] == NOVO and resposta.json()["pendente"] is True

    para, texto = emails[-1]
    assert para == NOVO and "Ana Admin" in texto
    assert cliente.post("/auth/login", json={"email": NOVO, "senha": "qualquer-coisa"}).status_code == 401

    assert _criar_senha(cliente, _token(texto)).status_code == 204
    assert cliente.post("/auth/login", json={"email": NOVO, "senha": "senha-da-nina"}).status_code == 200
    novo = _usuario(cliente, admin, NOVO)
    assert novo["pendente"] is False and novo["admin"] is False


def test_convite_recusa_email_invalido_e_repetido(cliente):
    admin = _cabecalho(cliente)
    invalido = cliente.post("/usuarios", headers=admin, json={"email": "sem-arroba", "nome": "X"})
    assert invalido.status_code == 400 and "e-mail válido" in invalido.json()["detail"]
    repetido = cliente.post("/usuarios", headers=admin, json={"email": COMUM.upper(), "nome": "Outro"})
    assert repetido.status_code == 400 and "Já existe" in repetido.json()["detail"]


def test_reenviar_convite_invalida_o_link_anterior(cliente, emails):
    admin = _cabecalho(cliente)
    usuario_id = cliente.post("/usuarios", headers=admin, json={"email": NOVO, "nome": "Nina"}).json()["id"]
    primeiro = _token(emails[-1][1])
    assert cliente.post(f"/usuarios/{usuario_id}/convite", headers=admin).status_code == 202
    segundo = _token(emails[-1][1])

    assert _criar_senha(cliente, primeiro).status_code == 400
    assert _criar_senha(cliente, segundo).status_code == 204
    assert cliente.post(f"/usuarios/{usuario_id}/convite", headers=admin).status_code == 400


def test_links_pendentes_caem_quando_a_senha_e_criada(cliente, emails):
    admin = _cabecalho(cliente)
    cliente.post("/usuarios", headers=admin, json={"email": NOVO, "nome": "Nina"})
    convite = _token(emails[-1][1])
    cliente.post("/auth/recuperar-senha", json={"email": NOVO})
    recuperacao = _token(emails[-1][1], "redefinir-senha")

    assert _criar_senha(cliente, convite).status_code == 204
    assert _criar_senha(cliente, recuperacao, "outra-senha").status_code == 400


def test_tornar_administrador(cliente):
    admin = _cabecalho(cliente)
    comum_id = _usuario(cliente, admin, COMUM)["id"]
    resposta = cliente.put(f"/usuarios/{comum_id}", headers=admin, json={"admin": True})
    assert resposta.status_code == 200 and resposta.json()["admin"] is True
    assert cliente.get("/usuarios", headers=_cabecalho(cliente, COMUM)).status_code == 200


def test_remover_encerra_o_acesso(cliente):
    admin = _cabecalho(cliente)
    comum = _cabecalho(cliente, COMUM)
    comum_id = _usuario(cliente, admin, COMUM)["id"]
    assert cliente.delete(f"/usuarios/{comum_id}", headers=admin).status_code == 204
    assert cliente.get("/auth/eu", headers=comum).status_code == 401
    assert cliente.post("/auth/login", json={"email": COMUM, "senha": SENHA}).status_code == 401
    assert cliente.delete(f"/usuarios/{comum_id}", headers=admin).status_code == 404


def test_administrador_nao_mexe_no_proprio_acesso(cliente):
    admin = _cabecalho(cliente)
    proprio = _usuario(cliente, admin, ADMIN)["id"]
    assert cliente.delete(f"/usuarios/{proprio}", headers=admin).status_code == 400
    assert cliente.put(f"/usuarios/{proprio}", headers=admin, json={"admin": False}).status_code == 400


def test_falha_no_envio_mantem_o_cadastro(cliente, monkeypatch):
    def sem_smtp(*_args, **_kwargs):
        raise OSError("SMTP fora do ar")

    monkeypatch.setattr(usuarios, "enviar_email", sem_smtp)
    admin = _cabecalho(cliente)
    resposta = cliente.post("/usuarios", headers=admin, json={"email": NOVO, "nome": "Nina"})
    assert resposta.status_code == 502 and "Reenviar convite" in resposta.json()["detail"]
    assert _usuario(cliente, admin, NOVO)["pendente"] is True

from datetime import datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.agente import historico as modulo_historico
from app.agente import seguranca
from app.agente.orquestrador import Resposta
from app.api import chat
from app.api.dependencias import usuario_atual
from app.autenticacao import Usuario
from app.main import app


class HistoricoFalso:
    def __init__(self):
        self.conversas: dict[str, dict] = {}

    def listar(self, usuario):
        proprias = [c for c in self.conversas.values() if c["usuario"] == usuario]
        return [modulo_historico.resumo(c) for c in sorted(proprias, key=lambda c: c["atualizada_em"], reverse=True)]

    def obter(self, usuario, conversa_id):
        conversa = self.conversas.get(conversa_id)
        return modulo_historico.completa(conversa) if conversa and conversa["usuario"] == usuario else None

    def criar(self, usuario, titulo):
        conversa = modulo_historico.nova_conversa(usuario, titulo)
        self.conversas[conversa["_id"]] = conversa
        return modulo_historico.completa(conversa)

    def acrescentar(self, usuario, conversa_id, mensagens):
        self.conversas[conversa_id]["mensagens"].extend(mensagens)
        self.conversas[conversa_id]["atualizada_em"] = datetime.now()

    def apagar(self, usuario, conversa_id):
        conversa = self.conversas.get(conversa_id)
        if conversa and conversa["usuario"] == usuario:
            del self.conversas[conversa_id]
            return True
        return False

    def apagar_antigas(self):
        limite = datetime.now() - timedelta(days=modulo_historico.RETENCAO_DIAS)
        for chave in [c for c, v in self.conversas.items() if v["atualizada_em"] < limite]:
            del self.conversas[chave]


@pytest.fixture
def historico():
    return HistoricoFalso()


@pytest.fixture
def estado():
    return {"usuario": Usuario(1, "ana@semob.sp.gov.br", "Ana"), "chamadas": []}


@pytest.fixture
def cliente(historico, estado, monkeypatch):
    def responder(mensagem, anteriores, conexao):
        estado["chamadas"].append((mensagem, anteriores))
        return Resposta(f"resposta para: {mensagem}", {"opcao": "consulta", "origem": "regras"},
                        [{"titulo": "t", "indicadores": [], "tabela": None}])

    monkeypatch.setattr(chat.orquestrador, "responder", responder)
    monkeypatch.setattr(chat, "limitador", seguranca.LimitadorDeTaxa(por_minuto=5, por_dia=100))
    app.dependency_overrides[usuario_atual] = lambda: estado["usuario"]
    app.dependency_overrides[chat.obter_historico] = lambda: historico
    app.dependency_overrides[chat.obter_conexao] = lambda: None
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_primeira_mensagem_abre_conversa_com_titulo(cliente):
    corpo = cliente.post("/chat", json={"mensagem": "Qual linha fez mais viagens?"}).json()
    assert corpo["titulo"] == "Qual linha fez mais viagens?"
    assert corpo["resposta"]["texto"] == "resposta para: Qual linha fez mais viagens?"
    assert corpo["resposta"]["dados"][0]["titulo"] == "t"


def test_continuacao_manda_o_historico_ao_orquestrador(cliente, estado):
    primeira = cliente.post("/chat", json={"mensagem": "Primeira"}).json()
    cliente.post("/chat", json={"mensagem": "Segunda", "conversa_id": primeira["conversa_id"]})
    _, anteriores = estado["chamadas"][-1]
    assert [m["papel"] for m in anteriores] == ["usuario", "assistente"]
    conversa = cliente.get(f"/chat/conversas/{primeira['conversa_id']}").json()
    assert len(conversa["mensagens"]) == 4


def test_cada_pessoa_ve_so_as_proprias_conversas(cliente, estado):
    da_ana = cliente.post("/chat", json={"mensagem": "Da Ana"}).json()
    estado["usuario"] = Usuario(2, "bia@semob.sp.gov.br", "Bia")
    assert cliente.get("/chat/conversas").json() == []
    assert cliente.get(f"/chat/conversas/{da_ana['conversa_id']}").status_code == 404
    assert cliente.post("/chat", json={"mensagem": "x", "conversa_id": da_ana["conversa_id"]}).status_code == 404


def test_apagar_conversa(cliente):
    conversa = cliente.post("/chat", json={"mensagem": "Apagar"}).json()
    assert cliente.delete(f"/chat/conversas/{conversa['conversa_id']}").status_code == 204
    assert cliente.get("/chat/conversas").json() == []


def test_conversas_antigas_somem(cliente, historico):
    conversa = cliente.post("/chat", json={"mensagem": "Antiga"}).json()
    historico.conversas[conversa["conversa_id"]]["atualizada_em"] = datetime.now() - timedelta(days=200)
    assert cliente.get("/chat/conversas").json() == []


def test_mensagem_vazia_ou_longa_demais_e_recusada(cliente):
    assert cliente.post("/chat", json={"mensagem": ""}).status_code == 422
    assert cliente.post("/chat", json={"mensagem": "x" * (seguranca.TAMANHO_MAXIMO + 1)}).status_code == 422


def test_limite_de_perguntas_por_minuto(cliente):
    for _ in range(5):
        assert cliente.post("/chat", json={"mensagem": "oi"}).status_code == 200
    resposta = cliente.post("/chat", json={"mensagem": "oi"})
    assert resposta.status_code == 429
    assert "Espere um minuto" in resposta.json()["detail"]

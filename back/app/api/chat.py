from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.engine import Connection

from app.agente import orquestrador
from app.agente.historico import HistoricoMongo, titulo_de
from app.agente.seguranca import TAMANHO_MAXIMO, LimiteExcedido, limitador
from app.api.dependencias import obter_conexao, usuario_atual
from app.autenticacao import Usuario

rotas = APIRouter(prefix="/chat", tags=["chat"])


def obter_historico() -> HistoricoMongo:
    from app.db.mongo import banco_bruto

    return HistoricoMongo(banco_bruto())


Conexao = Annotated[Connection, Depends(obter_conexao)]
Logado = Annotated[Usuario, Depends(usuario_atual)]
Conversas = Annotated[HistoricoMongo, Depends(obter_historico)]


class PedidoChat(BaseModel):
    mensagem: str = Field(min_length=1, max_length=TAMANHO_MAXIMO)
    conversa_id: str | None = Field(default=None, max_length=64)


@rotas.post("")
def conversar(pedido: PedidoChat, usuario: Logado, conexao: Conexao, historico: Conversas) -> dict:
    try:
        limitador.registrar(usuario.email)
    except LimiteExcedido as erro:
        raise HTTPException(status_code=429, detail=str(erro)) from erro

    if pedido.conversa_id:
        conversa = historico.obter(usuario.email, pedido.conversa_id)
        if conversa is None:
            raise HTTPException(status_code=404, detail="Conversa não encontrada.")
    else:
        conversa = historico.criar(usuario.email, titulo_de(pedido.mensagem))

    anteriores = [{"papel": m["papel"], "texto": m["texto"]} for m in conversa["mensagens"]]
    resposta = orquestrador.responder(pedido.mensagem, anteriores, conexao)
    historico.acrescentar(
        usuario.email,
        conversa["id"],
        [
            {"papel": "usuario", "texto": pedido.mensagem, "em": datetime.now()},
            {"papel": "assistente", "texto": resposta.texto, "decisao": resposta.decisao,
             "dados": resposta.dados, "em": datetime.now()},
        ],
    )
    return {
        "conversa_id": conversa["id"],
        "titulo": conversa["titulo"],
        "resposta": {"texto": resposta.texto, "decisao": resposta.decisao, "dados": resposta.dados},
    }


@rotas.get("/conversas")
def listar(usuario: Logado, historico: Conversas) -> list[dict]:
    historico.apagar_antigas()
    return historico.listar(usuario.email)


@rotas.get("/conversas/{conversa_id}")
def obter(conversa_id: str, usuario: Logado, historico: Conversas) -> dict:
    conversa = historico.obter(usuario.email, conversa_id)
    if conversa is None:
        raise HTTPException(status_code=404, detail="Conversa não encontrada.")
    return conversa


@rotas.delete("/conversas/{conversa_id}", status_code=204)
def apagar(conversa_id: str, usuario: Logado, historico: Conversas) -> Response:
    if not historico.apagar(usuario.email, conversa_id):
        raise HTTPException(status_code=404, detail="Conversa não encontrada.")
    return Response(status_code=204)

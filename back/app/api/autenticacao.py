from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.engine import Connection

from app import autenticacao
from app.api.dependencias import obter_conexao, token_do_cabecalho, usuario_atual
from app.autenticacao import ErroAutenticacao, Usuario

rotas = APIRouter(prefix="/auth", tags=["autenticacao"])

Conexao = Annotated[Connection, Depends(obter_conexao)]


class PedidoLogin(BaseModel):
    email: str = Field(min_length=3, max_length=200)
    senha: str = Field(min_length=1, max_length=200)


class PedidoRecuperacao(BaseModel):
    email: str = Field(min_length=3, max_length=200)


class PedidoRedefinicao(BaseModel):
    token: str = Field(min_length=10, max_length=200)
    senha: str = Field(min_length=1, max_length=200)


def _usuario_json(usuario: Usuario) -> dict:
    return {"email": usuario.email, "nome": usuario.nome, "admin": usuario.admin}


@rotas.post("/login")
def login(pedido: PedidoLogin, conexao: Conexao) -> dict:
    try:
        token, usuario = autenticacao.entrar(conexao, pedido.email, pedido.senha)
    except ErroAutenticacao as erro:
        raise HTTPException(status_code=401, detail=str(erro)) from erro
    return {"token": token, "usuario": _usuario_json(usuario)}


@rotas.get("/eu")
def eu(usuario: Annotated[Usuario, Depends(usuario_atual)]) -> dict:
    return _usuario_json(usuario)


@rotas.post("/sair", status_code=204)
def sair(conexao: Conexao, token: Annotated[str, Depends(token_do_cabecalho)]) -> Response:
    autenticacao.sair(conexao, token)
    return Response(status_code=204)


@rotas.post("/recuperar-senha", status_code=202)
def recuperar_senha(pedido: PedidoRecuperacao, conexao: Conexao) -> Response:
    autenticacao.pedir_recuperacao(conexao, pedido.email)
    return Response(status_code=202)


@rotas.post("/redefinir-senha", status_code=204)
def redefinir_senha(pedido: PedidoRedefinicao, conexao: Conexao) -> Response:
    try:
        autenticacao.redefinir_senha(conexao, pedido.token, pedido.senha)
    except ErroAutenticacao as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro
    return Response(status_code=204)

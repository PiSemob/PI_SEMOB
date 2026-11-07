from collections.abc import Iterator
from contextlib import contextmanager
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.engine import Connection

from app import usuarios
from app.api.dependencias import administrador_atual, obter_conexao
from app.autenticacao import ErroAutenticacao, Usuario

rotas = APIRouter(prefix="/usuarios", tags=["usuarios"])

Conexao = Annotated[Connection, Depends(obter_conexao)]
Administrador = Annotated[Usuario, Depends(administrador_atual)]


class Convite(BaseModel):
    email: str = Field(min_length=3, max_length=200)
    nome: str = Field(min_length=1, max_length=200)
    admin: bool = False


class Perfil(BaseModel):
    admin: bool


@contextmanager
def _respostas_de_erro() -> Iterator[None]:
    try:
        yield
    except usuarios.UsuarioNaoEncontrado as erro:
        raise HTTPException(status_code=404, detail=str(erro)) from erro
    except ErroAutenticacao as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro
    except OSError as erro:
        raise HTTPException(
            status_code=502,
            detail="O cadastro foi salvo, mas o e-mail do convite não saiu. Tente \"Reenviar convite\".",
        ) from erro


@rotas.get("")
def listar(conexao: Conexao, _: Administrador) -> list[dict]:
    return usuarios.listar(conexao)


@rotas.post("", status_code=201)
def convidar(convite: Convite, conexao: Conexao, quem: Administrador) -> dict:
    with _respostas_de_erro():
        return usuarios.convidar(conexao, convite.email, convite.nome, convite.admin, quem)


@rotas.post("/{usuario_id}/convite", status_code=202)
def reenviar_convite(usuario_id: int, conexao: Conexao, quem: Administrador) -> Response:
    with _respostas_de_erro():
        usuarios.reenviar_convite(conexao, usuario_id, quem)
    return Response(status_code=202)


@rotas.put("/{usuario_id}")
def definir_perfil(usuario_id: int, perfil: Perfil, conexao: Conexao, quem: Administrador) -> dict:
    with _respostas_de_erro():
        return usuarios.definir_admin(conexao, usuario_id, perfil.admin, quem)


@rotas.delete("/{usuario_id}", status_code=204)
def remover(usuario_id: int, conexao: Conexao, quem: Administrador) -> Response:
    with _respostas_de_erro():
        usuarios.remover(conexao, usuario_id, quem)
    return Response(status_code=204)

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.engine import Connection

from app import configuracoes
from app.api.dependencias import obter_conexao, usuario_atual
from app.autenticacao import Usuario

rotas = APIRouter(prefix="/configuracoes", tags=["configuracoes"])

Conexao = Annotated[Connection, Depends(obter_conexao)]
Logado = Annotated[Usuario, Depends(usuario_atual)]


class Mudancas(BaseModel):
    organizacao: str | None = Field(default=None, max_length=120)
    cidade: str | None = Field(default=None, max_length=120)
    alertas_anomalia: bool | None = None
    relatorios_automaticos: bool | None = None
    email_relatorios: str | None = Field(default=None, max_length=200)


@rotas.get("")
def ler(usuario: Logado, conexao: Conexao) -> dict:
    return configuracoes.ler(conexao)


@rotas.put("")
def salvar(mudancas: Mudancas, usuario: Logado, conexao: Conexao) -> dict:
    try:
        return configuracoes.salvar(conexao, mudancas.model_dump(exclude_none=True))
    except configuracoes.ErroConfiguracao as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro

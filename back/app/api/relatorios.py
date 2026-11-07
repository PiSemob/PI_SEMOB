from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.engine import Connection

from app.api.dependencias import obter_conexao, usuario_atual
from app.autenticacao import Usuario
from app.relatorios import exportacao, montagem

rotas = APIRouter(prefix="/relatorios", tags=["relatorios"])

Conexao = Annotated[Connection, Depends(obter_conexao)]
Logado = Annotated[Usuario, Depends(usuario_atual)]
Modelo = Literal["executivo", "operacional", "financeiro", "prestacao_contas"]
Celula = float | int | str | None


class Indicador(BaseModel):
    nome: str = Field(max_length=200)
    valor: Celula
    unidade: str = Field(default="", max_length=30)


class Tabela(BaseModel):
    colunas: list[str] = Field(max_length=20)
    linhas: list[list[Celula]] = Field(max_length=5000)


class Secao(BaseModel):
    titulo: str = Field(max_length=200)
    texto: str = Field(default="", max_length=5000)
    indicadores: list[Indicador] = Field(default=[], max_length=30)
    tabela: Tabela | None = None


class Relatorio(BaseModel):
    modelo: Modelo
    titulo: str = Field(max_length=200)
    organizacao: str = Field(max_length=120)
    cidade: str = Field(max_length=120)
    inicio: date
    fim: date
    gerado_em: str = Field(max_length=40)
    resumo: str = Field(max_length=10000)
    secoes: list[Secao] = Field(max_length=30)


class PedidoGerar(BaseModel):
    modelo: Modelo
    inicio: date
    fim: date


class PedidoExportar(PedidoGerar):
    formato: Literal["pdf", "xlsx", "csv"]
    relatorio: Relatorio | None = None


@rotas.post("/gerar")
def gerar(pedido: PedidoGerar, usuario: Logado, conexao: Conexao) -> dict:
    try:
        return montagem.montar(pedido.modelo, pedido.inicio, pedido.fim, conexao)
    except ValueError as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro


def _conteudo(pedido: PedidoExportar, relatorio: dict, conexao: Connection) -> bytes:
    if pedido.formato == "pdf":
        return exportacao.para_pdf(relatorio)
    if pedido.formato == "xlsx":
        return exportacao.para_xlsx(relatorio)
    return exportacao.para_csv(*montagem.dados_diarios(conexao, pedido.inicio, pedido.fim))


@rotas.post("/exportar")
def exportar(pedido: PedidoExportar, usuario: Logado, conexao: Conexao) -> Response:
    try:
        relatorio = (pedido.relatorio.model_dump(mode="json") if pedido.relatorio
                     else montagem.montar(pedido.modelo, pedido.inicio, pedido.fim, conexao))
        conteudo = _conteudo(pedido, relatorio, conexao)
    except ValueError as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro
    return Response(
        content=conteudo,
        media_type=exportacao.TIPOS[pedido.formato],
        headers={"Content-Disposition": f'attachment; filename="{exportacao.nome_do_arquivo(relatorio, pedido.formato)}"'},
    )

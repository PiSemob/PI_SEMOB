# o que as rotas tem em comum


"""O que as rotas têm em comum: a conexão com o banco, a validação do período e o formato JSON."""

from collections.abc import Iterator
from datetime import date
from decimal import Decimal
from typing import Annotated

import pandas as pd
from fastapi import Depends, Header, HTTPException
from sqlalchemy.engine import Connection

from app.autenticacao import Usuario, usuario_da_sessao


def obter_conexao() -> Iterator[Connection]:
    """Abre uma conexão com o PostgreSQL para a rota e fecha quando ela termina.

    As rotas recebem a conexão por `Depends(obter_conexao)`. Nos testes, essa
    função é trocada por uma que entrega um banco em memória.
    """
    from app.db.postgres import criar_engine

    with criar_engine().connect() as conexao:
        yield conexao


def validar_periodo(inicio: date, fim: date) -> None:
    if inicio > fim:
        raise HTTPException(status_code=400, detail="A data de início é depois da data de fim.")


def linhas_da_consulta(conexao: Connection, consulta) -> list[dict]:
    """Executa a consulta e devolve cada linha como dicionário.

    O banco devolve quilometragem e dinheiro como Decimal, que o FastAPI escreve
    no JSON como texto ("700.00"). Aqui eles viram número.
    """
    return [
        {
            coluna: float(valor) if isinstance(valor, Decimal) else valor
            for coluna, valor in linha.items()
        }
        for linha in conexao.execute(consulta).mappings()
    ]


def tabela_para_json(tabela: pd.DataFrame) -> list[dict]:
    """Transforma a tabela de um modelo em uma lista pronta para virar JSON.

    Datas viram texto ('2026-08-01' ou '2026-08-01T04:34:22') e os vazios do
    pandas viram null.
    """
    tabela = tabela.copy()
    for coluna in tabela.columns:
        if pd.api.types.is_datetime64_any_dtype(tabela[coluna]):
            so_data = (tabela[coluna].dt.normalize() == tabela[coluna]).all()
            tabela[coluna] = tabela[coluna].dt.strftime("%Y-%m-%d" if so_data else "%Y-%m-%dT%H:%M:%S")
    return tabela.astype(object).where(tabela.notna(), None).to_dict("records")


def token_do_cabecalho(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Entre no Ferret para continuar.")
    return authorization.split(" ", 1)[1].strip()


def usuario_atual(
    token: Annotated[str, Depends(token_do_cabecalho)],
    conexao: Annotated[Connection, Depends(obter_conexao)],
) -> Usuario:
    usuario = usuario_da_sessao(conexao, token)
    if usuario is None:
        raise HTTPException(status_code=401, detail="Sua sessão expirou. Entre de novo.")
    return usuario


def administrador_atual(usuario: Annotated[Usuario, Depends(usuario_atual)]) -> Usuario:
    if not usuario.admin:
        raise HTTPException(status_code=403, detail="Só administradores podem gerenciar usuários.")
    return usuario

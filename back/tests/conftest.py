"""Fixtures compartilhadas pelos testes (as funções de apoio ficam em tests/apoio.py)."""

import os
from collections import defaultdict
from pathlib import Path

import pandas as pd
import pytest
from pymongo import MongoClient
from pymongo.errors import PyMongoError
from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError

from app.config import config
from app.etl.carga_bruta import montar_documentos
from app.etl.limpeza import limpar_tudo, tabela_bruta
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import TIPOS, identificar
from tests.apoio import (
    BACK,
    BANCO_CARGA,
    BRUTOS,
    Carga,
    contar,
    recriar_mongo,
    recriar_postgres,
    rodar_script,
    url_postgres,
)

_MARCA_POR_PASTA = {
    "integracao": "integracao",
    "sistema": "sistema",
    "aceitacao": "aceitacao",
    "regressao": "regressao",
    "bdd": "bdd",
}


HISTORIAS = ("H01", "H02", "H03", "H04")
REQUISITOS = ("RF01", "RF02", "RF03", "RF04", "RF05", "RF06", "RNF01", "RNF02", "RNF03")


def pytest_configure(config):
    """As tags dos .feature viram marcas: `pytest -m H02`, `pytest -m RF03`."""
    for tag in (*HISTORIAS, *REQUISITOS):
        config.addinivalue_line("markers", f"{tag}: ver a matriz em docs/testes.md")


def pytest_collection_modifyitems(items):
    """Marca cada teste pela pasta: `pytest -m integracao`, `pytest -m "not sistema"`..."""
    for item in items:
        pasta = Path(item.fspath).relative_to(BACK / "tests").parts[0]
        item.add_marker(_MARCA_POR_PASTA.get(pasta, "unidade"))


@pytest.fixture(scope="session")
def limpas() -> dict[str, pd.DataFrame]:
    """Lê os 44 arquivos e limpa tudo em memória, uma vez só para a sessão inteira."""
    documentos = defaultdict(list)
    for caminho in sorted(BRUTOS.rglob("*.html")):
        for relatorio in ler_arquivo(caminho):
            tipo = identificar(relatorio.titulo)
            documentos[tipo.chave].extend(montar_documentos(relatorio, tipo))
    tipos = {tipo.chave: tipo for tipo in TIPOS}
    return limpar_tudo(lambda chave: tabela_bruta(documentos[chave], tipos[chave]))


@pytest.fixture(scope="session")
def bancos_no_ar() -> None:
    """Pula os testes de banco se os containers não estiverem rodando (no CI, falha)."""
    try:
        MongoClient(config.mongo_url, serverSelectionTimeoutMS=3000).admin.command("ping")
        with create_engine(url_postgres("postgres")).connect():
            pass
    except (PyMongoError, SQLAlchemyError, OSError) as erro:
        mensagem = f"MongoDB/PostgreSQL fora do ar: {erro}. Rode `docker compose up -d` na raiz."
        if os.environ.get("CI"):
            pytest.fail(mensagem)
        pytest.skip(mensagem)


@pytest.fixture(scope="session")
def carga(bancos_no_ar) -> Carga:
    """Bancos de teste zerados, `criar_tabelas` e depois `ingerir` rodado duas vezes."""
    resultado = Carga(recriar_mongo(BANCO_CARGA), recriar_postgres(BANCO_CARGA))
    rodar_script("scripts.criar_tabelas", BANCO_CARGA)
    for _ in range(2):
        saida, segundos = rodar_script("scripts.ingerir", BANCO_CARGA)
        resultado.saidas.append(saida)
        resultado.segundos.append(segundos)
        resultado.contagens.append(contar(resultado.mongo, resultado.engine))
    yield resultado
    resultado.engine.dispose()

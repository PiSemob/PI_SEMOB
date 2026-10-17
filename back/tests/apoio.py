"""Funções de apoio dos testes que usam os bancos reais (as fixtures ficam em conftest.py).

Os testes usam os containers do `docker-compose.yml`, mas em bancos separados
(`semob_teste...`). Os bancos de trabalho (`semob`) nunca são tocados.
"""

import os
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

from pymongo import MongoClient
from pymongo.database import Database
from sqlalchemy import Engine, create_engine, func, select, text
from sqlalchemy.engine import URL, make_url

from app.config import config
from app.db.tabelas import metadata
from app.etl.parsers.leitura import ler_arquivo

BACK = Path(__file__).resolve().parents[1]
BRUTOS = BACK.parent / "dados" / "brutos"

BANCO_CARGA = "semob_teste"  # sistema, aceitação e BDD
BANCO_INTEGRACAO = "semob_teste_integracao"


def url_postgres(banco: str) -> URL:
    return make_url(config.postgres_url).set(database=banco)


def recriar_postgres(banco: str) -> Engine:
    """Apaga e cria de novo um banco de teste no PostgreSQL, e devolve a conexão."""
    admin = create_engine(url_postgres("postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as conexao:
        conexao.execute(text(f'DROP DATABASE IF EXISTS "{banco}" WITH (FORCE)'))
        conexao.execute(text(f'CREATE DATABASE "{banco}"'))
    admin.dispose()
    return create_engine(url_postgres(banco))


def recriar_mongo(banco: str) -> Database:
    cliente = MongoClient(config.mongo_url)
    cliente.drop_database(banco)
    return cliente[banco]


def contar(mongo: Database, engine: Engine) -> dict[str, dict[str, int]]:
    """Quantos registros há em cada coleção do MongoDB e em cada tabela do PostgreSQL."""
    with engine.connect() as conexao:
        postgres = {
            nome: conexao.scalar(select(func.count()).select_from(tabela))
            for nome, tabela in metadata.tables.items()
        }
    return {
        "mongo": {nome: mongo[nome].count_documents({}) for nome in mongo.list_collection_names()},
        "postgres": postgres,
    }


def rodar_script(modulo: str, banco: str) -> tuple[str, float]:
    """Roda `python -m <modulo>` de dentro de back/, apontando para os bancos de teste.

    As variáveis de ambiente têm prioridade sobre o .env, então o script real
    roda sem nenhuma alteração, só que em outro banco.
    """
    ambiente = {
        **os.environ,
        "MONGO_DB": banco,
        "POSTGRES_URL": url_postgres(banco).render_as_string(hide_password=False),
        "PYTHONIOENCODING": "utf-8",
    }
    inicio = time.perf_counter()
    resultado = subprocess.run(
        [sys.executable, "-m", modulo],
        cwd=BACK, env=ambiente, capture_output=True, text=True, encoding="utf-8", check=False,
    )
    segundos = time.perf_counter() - inicio
    assert resultado.returncode == 0, f"{modulo} falhou:\n{resultado.stdout}\n{resultado.stderr}"
    return resultado.stdout, segundos


# ------------------------------------------------- totais lidos direto do HTML
#
# A aceitação não usa o código de limpeza do app: lê o "Total Geral" que o próprio
# Smart Report imprime no fim de cada relatório e converte os números aqui mesmo.


def inteiro_br(texto: str) -> int:
    return int(texto.replace(".", ""))


def numero_br(texto: str) -> float:
    return float(texto.replace(".", "").replace(",", "."))


def data_br(texto: str):
    dia, mes, ano = texto.split("/")
    return date(int(ano), int(mes), int(dia))


@dataclass
class ResumoGeralHtml:
    arquivo: str
    datas: list[date]
    viagens_programadas: int
    viagens_realizadas: int
    km_prod: float
    km_improd: float
    km_total: float


def resumo_geral_do_html(caminho: Path) -> ResumoGeralHtml:
    """As datas e a linha "Total Geral" de um relatório Resumo Geral (Mensal_*/Quinzenal_*)."""
    (relatorio,) = ler_arquivo(caminho)
    tabela = relatorio.tabela
    dias = tabela[tabela["Data"].str.match(r"\d{2}/\d{2}/\d{4}")]
    (total,) = tabela[tabela["Data"] == "Total Geral"].to_dict("records")
    return ResumoGeralHtml(
        arquivo=relatorio.arquivo,
        datas=[data_br(d) for d in dias["Data"]],
        viagens_programadas=inteiro_br(total["nrViagensProgr"]),
        viagens_realizadas=inteiro_br(total["nrViagensRealiz"]),
        km_prod=numero_br(total["kmProd"]),
        km_improd=numero_br(total["kmImprod"]),
        km_total=numero_br(total["kmTotal"]),
    )


ARQUIVOS_RESUMO_GERAL = sorted(BRUTOS.rglob("*_2026??.html"))
ARQUIVOS_RESUMO_GERAL = [p for p in ARQUIVOS_RESUMO_GERAL if p.stem.count("_") == 1]
ARQUIVOS_PASSAGEIROS = sorted(BRUTOS.rglob("Passageiros*.html"))


@dataclass
class Carga:
    """Resultado de `criar_tabelas` + `ingerir` rodados nos bancos de teste."""

    mongo: Database
    engine: Engine
    saidas: list[str] = field(default_factory=list)  # o que cada execução imprimiu
    contagens: list[dict] = field(default_factory=list)  # bancos depois de cada execução
    segundos: list[float] = field(default_factory=list)

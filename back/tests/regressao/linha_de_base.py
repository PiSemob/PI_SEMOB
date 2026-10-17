"""Linha de base da regressão: o que a leitura e a limpeza produzem hoje, arquivo por arquivo
e mês por mês. Fica gravada em `linha_de_base.json`, versionada no Git.

Quando um parser ou um mês novo entrar, os testes de regressão conferem que os
meses que já existiam continuam iguais. Se a mudança for intencional (por exemplo,
uma correção na limpeza), gere a linha de base de novo e explique no commit:

    python -m tests.regressao.linha_de_base
"""

import json
from collections import defaultdict
from datetime import date
from pathlib import Path

import pandas as pd

from app.etl.carga_bruta import montar_documentos
from app.etl.limpeza import limpar_tudo, tabela_bruta
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import TIPOS, identificar

BRUTOS = Path(__file__).resolve().parents[3] / "dados" / "brutos"
ARQUIVO = Path(__file__).with_name("linha_de_base.json")


def medir_arquivo(caminho: Path) -> list[dict]:
    """Para cada relatório do arquivo: o tipo, as colunas e quantas linhas foram lidas."""
    return [
        {
            "tipo": identificar(relatorio.titulo).chave,
            "colunas": list(relatorio.tabela.columns),
            "linhas": len(relatorio.tabela),
            "gerado_em": relatorio.gerado_em,
        }
        for relatorio in ler_arquivo(caminho)
    ]


def medir_tabela(df: pd.DataFrame) -> dict[str, dict]:
    """Por mês: quantos registros, quantos suspeitos e a soma de cada coluna numérica."""
    meses = pd.to_datetime(df["data"]).dt.strftime("%Y-%m")
    numericas = [
        coluna for coluna in df.select_dtypes("number").columns if coluna != "suspeito"
    ]
    resultado = {}
    for mes, grupo in df.groupby(meses):
        resultado[mes] = {
            "registros": len(grupo),
            "suspeitos": int(grupo["suspeito"].sum()),
            "somas": {coluna: round(float(grupo[coluna].sum()), 2) for coluna in numericas},
        }
    return resultado


def limpar_em_memoria() -> dict[str, pd.DataFrame]:
    documentos = defaultdict(list)
    for caminho in sorted(BRUTOS.rglob("*.html")):
        for relatorio in ler_arquivo(caminho):
            tipo = identificar(relatorio.titulo)
            documentos[tipo.chave].extend(montar_documentos(relatorio, tipo))
    tipos = {tipo.chave: tipo for tipo in TIPOS}
    return limpar_tudo(lambda chave: tabela_bruta(documentos[chave], tipos[chave]))


def gerar() -> dict:
    return {
        "gerada_em": date.today().isoformat(),
        "arquivos": {
            caminho.relative_to(BRUTOS).as_posix(): medir_arquivo(caminho)
            for caminho in sorted(BRUTOS.rglob("*.html"))
        },
        "tabelas": {nome: medir_tabela(df) for nome, df in limpar_em_memoria().items()},
    }


def carregar() -> dict:
    return json.loads(ARQUIVO.read_text(encoding="utf-8"))


if __name__ == "__main__":
    ARQUIVO.write_text(json.dumps(gerar(), ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"linha de base gravada em {ARQUIVO}")

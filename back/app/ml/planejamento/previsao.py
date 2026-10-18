# escolha do modelo de previsão por série


"""Porta de entrada da previsão: usa, para cada série, o modelo que errou menos.

A escolha é feita pelo script `scripts/treinar.py`, que compara Prophet e SARIMAX
nos últimos dias de cada série e grava o resultado em `back/modelos/escolhas.json`.
"""

import json
from pathlib import Path

import pandas as pd

from app.ml.planejamento import avaliacao, previsao_prophet, previsao_sarimax

MODELOS = {
    previsao_prophet.NOME: previsao_prophet,
    previsao_sarimax.NOME: previsao_sarimax,
}
PADRAO = previsao_prophet.NOME

ARQUIVO_DE_ESCOLHAS = Path(__file__).resolve().parents[3] / "modelos" / "escolhas.json"


def chave(nome: str, linha: str | None) -> str:
    """Identificador de uma série no arquivo de escolhas: 'viagens:04', 'passageiros:sistema'."""
    return f"{nome}:{linha or 'sistema'}"


def comparar(serie: pd.DataFrame) -> dict:
    """Valida os dois modelos na mesma série e devolve o erro de cada um."""
    return {
        nome: avaliacao.validar(modelo.prever_serie, serie) for nome, modelo in MODELOS.items()
    }


def escolher(erros: dict) -> str:
    """Nome do modelo com o menor erro médio absoluto."""
    return min(erros, key=lambda nome: erros[nome]["mae"])


def modelo_escolhido(nome: str, linha: str | None) -> str:
    """Lê do arquivo qual modelo usar para a série. Sem arquivo, usa o padrão."""
    if not ARQUIVO_DE_ESCOLHAS.exists():
        return PADRAO
    escolhas = json.loads(ARQUIVO_DE_ESCOLHAS.read_text(encoding="utf-8"))
    return escolhas.get("series", {}).get(chave(nome, linha), {}).get("modelo", PADRAO)


def prever(nome: str, dias: int = 7, linha: str | None = None) -> dict:
    """Previsão dos próximos dias com o modelo escolhido para a série."""
    escolhido = modelo_escolhido(nome, linha)
    return MODELOS[escolhido].prever(nome, dias, linha)

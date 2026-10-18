# previsão de serie temporal


"""Previsão de séries diárias com o Prophet.

O Prophet decompõe a série em tendência, padrão da semana e efeito de feriado,
e soma as três partes para prever.
"""

import logging

import pandas as pd
from prophet import Prophet

from app.ml import dados
from app.ml.planejamento import avaliacao

for _nome in ("cmdstanpy", "prophet"):
    logging.getLogger(_nome).addHandler(logging.NullHandler())
    logging.getLogger(_nome).setLevel(logging.WARNING)

NOME = "prophet"


def prever_serie(serie: pd.DataFrame, dias: int) -> pd.DataFrame:
    """Treina com a série (colunas `ds` e `y`) e prevê os `dias` dias seguintes."""
    futuro = avaliacao.datas_futuras(serie, dias)
    todas = pd.concat([serie["ds"], pd.Series(futuro)], ignore_index=True)
    feriados = pd.DataFrame({"holiday": "feriado", "ds": todas[avaliacao.eh_feriado(todas)]})

    modelo = Prophet(
        growth="flat",
        weekly_seasonality=True,
        yearly_seasonality=False,
        daily_seasonality=False,
        holidays=feriados if not feriados.empty else None,
    )
    modelo.fit(serie[["ds", "y"]])
    previsao = modelo.predict(pd.DataFrame({"ds": futuro}))
    return avaliacao.formatar(
        previsao["ds"], previsao["yhat"], previsao["yhat_lower"], previsao["yhat_upper"]
    )


def prever(nome: str, dias: int = 7, linha: str | None = None) -> dict:
    """Lê a série do banco, mede o erro na validação e prevê os próximos dias."""
    serie = dados.ler_serie(nome, linha)
    erro = avaliacao.validar(prever_serie, serie)
    return avaliacao.responder(nome, linha, NOME, prever_serie(serie, dias), erro)

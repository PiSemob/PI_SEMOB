# previsão de serie temporal


"""Previsão de séries diárias com o SARIMAX.

Modelo estatístico que prevê cada dia a partir do mesmo dia da semana anterior
(a parte sazonal, de período 7), do dia de ontem (a parte autorregressiva) e de
uma variável externa que avisa quando é feriado.
"""

import warnings

import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX

from app.ml import dados
from app.ml.planejamento import avaliacao

NOME = "sarimax"
ORDEM = (1, 0, 0)
ORDEM_SAZONAL = (0, 1, 1, 7)


def _feriado(datas) -> pd.DataFrame:
    return pd.DataFrame({"feriado": avaliacao.eh_feriado(datas).astype(float)})


def prever_serie(serie: pd.DataFrame, dias: int) -> pd.DataFrame:
    """Treina com a série (colunas `ds` e `y`) e prevê os `dias` dias seguintes."""
    futuro = avaliacao.datas_futuras(serie, dias)
    externa_treino, externa_futuro = _feriado(serie["ds"]), _feriado(futuro)
    usar_feriado = externa_treino["feriado"].nunique() > 1

    modelo = SARIMAX(
        serie["y"].to_numpy(),
        exog=externa_treino.to_numpy() if usar_feriado else None,
        order=ORDEM,
        seasonal_order=ORDEM_SAZONAL,
        enforce_stationarity=False,
        enforce_invertibility=False,
    )
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        ajustado = modelo.fit(disp=False, maxiter=200)
    previsao = ajustado.get_forecast(
        dias, exog=externa_futuro.to_numpy() if usar_feriado else None
    )
    intervalo = previsao.conf_int(alpha=0.2)
    return avaliacao.formatar(futuro, previsao.predicted_mean, intervalo[:, 0], intervalo[:, 1])


def prever(nome: str, dias: int = 7, linha: str | None = None) -> dict:
    """Lê a série do banco, mede o erro na validação e prevê os próximos dias."""
    serie = dados.ler_serie(nome, linha)
    erro = avaliacao.validar(prever_serie, serie)
    return avaliacao.responder(nome, linha, NOME, prever_serie(serie, dias), erro)

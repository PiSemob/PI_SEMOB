# calendário, validação e formato de resposta comuns aos modelos de previsão


"""O que os dois modelos de previsão têm em comum: calendário, validação e formato da resposta.

Prophet e SARIMAX expõem a mesma função `prever_serie(serie, dias)`. Por isso a
validação e a resposta são escritas uma vez só, aqui.
"""

from typing import Callable

import holidays
import pandas as pd

DIAS_DE_TESTE = 14
FERIADOS_MUNICIPAIS = ((7, 28),)


def eh_feriado(datas) -> pd.Series:
    """Verdadeiro para feriado nacional, do estado de São Paulo ou municipal."""
    datas = pd.Series(pd.to_datetime(datas)).reset_index(drop=True)
    calendario = holidays.Brazil(subdiv="SP")
    return datas.map(
        lambda dia: dia.date() in calendario or (dia.month, dia.day) in FERIADOS_MUNICIPAIS
    )


def datas_futuras(serie: pd.DataFrame, dias: int) -> pd.DatetimeIndex:
    """Os `dias` dias seguintes ao último dia da série."""
    return pd.date_range(serie["ds"].max() + pd.Timedelta(days=1), periods=dias)


def formatar(datas, previsto, minimo, maximo) -> pd.DataFrame:
    """Tabela de saída dos dois modelos. Nenhuma das séries pode ser negativa."""
    tabela = pd.DataFrame(
        {"ds": pd.to_datetime(datas), "previsto": previsto, "minimo": minimo, "maximo": maximo}
    )
    colunas = ["previsto", "minimo", "maximo"]
    tabela[colunas] = tabela[colunas].astype(float).clip(lower=0).round(1)
    return tabela


def medir(real: pd.Series, previsto: pd.Series) -> dict:
    """Erro médio absoluto (MAE) e erro percentual médio (MAPE)."""
    diferenca = (real.to_numpy() - previsto.to_numpy()).__abs__()
    return {
        "mae": round(float(diferenca.mean()), 1),
        "mape": round(float((diferenca / real.to_numpy()).mean() * 100), 1),
    }


def validar(
    prever_serie: Callable[[pd.DataFrame, int], pd.DataFrame],
    serie: pd.DataFrame,
    dias_de_teste: int = DIAS_DE_TESTE,
) -> dict:
    """Esconde os últimos dias, prevê com o resto e compara com o que aconteceu."""
    if len(serie) < dias_de_teste * 3:
        raise ValueError(f"Série curta demais para validar: {len(serie)} dias.")
    treino, teste = serie.iloc[:-dias_de_teste], serie.iloc[-dias_de_teste:]
    previsao = prever_serie(treino, dias_de_teste)
    return medir(teste["y"], previsao["previsto"])


def responder(nome: str, linha: str | None, modelo: str, previsao: pd.DataFrame, erro: dict) -> dict:
    """Formato final que a API e o agente recebem."""
    return {
        "serie": nome,
        "linha": linha,
        "modelo": modelo,
        "erro_na_validacao": erro,
        "previsao": [
            {
                "data": dia.ds.date().isoformat(),
                "previsto": dia.previsto,
                "minimo": dia.minimo,
                "maximo": dia.maximo,
            }
            for dia in previsao.itertuples()
        ],
    }

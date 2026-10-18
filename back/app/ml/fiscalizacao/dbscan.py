# detecção de anomalia por agrupamento de densidade


"""DBSCAN: aponta as viagens que não se parecem com nenhuma outra da mesma linha.

O modelo agrupa as viagens por proximidade. A viagem que não cabe em nenhum grupo
recebe o rótulo -1 ("ruído") e é a que interessa para a fiscalização.
"""

from datetime import date

import pandas as pd
from sklearn.cluster import DBSCAN
from sklearn.preprocessing import StandardScaler

from app.ml import dados

VARIAVEIS = ["duracao_min", "km_total"]
EPS = 0.8
MIN_AMOSTRAS = 10
MINIMO_DE_VIAGENS = 50


def marcar_ruido(
    viagens: pd.DataFrame, eps: float = EPS, min_amostras: int = MIN_AMOSTRAS
) -> pd.DataFrame:
    """Devolve as viagens com as colunas `grupo`, `ruido` e as medianas de comparação.

    O agrupamento é feito dentro de cada linha e sentido, porque ida e volta têm
    percursos diferentes.
    """
    partes = []
    for _, grupo in viagens.groupby(["linha", "sentido"]):
        if len(grupo) < MINIMO_DE_VIAGENS:
            continue
        grupo = grupo.copy()
        padronizado = StandardScaler().fit_transform(grupo[VARIAVEIS])
        grupo["grupo"] = DBSCAN(eps=eps, min_samples=min_amostras).fit_predict(padronizado)
        grupo["ruido"] = grupo["grupo"] == -1
        grupo["mediana_duracao"] = grupo["duracao_min"].median()
        grupo["mediana_km"] = grupo["km_total"].median()
        partes.append(grupo)
    if not partes:
        raise ValueError(f"Nenhuma linha e sentido com pelo menos {MINIMO_DE_VIAGENS} viagens.")
    return pd.concat(partes, ignore_index=True)


def viagens_atipicas(inicio: date, fim: date, linha: str) -> pd.DataFrame:
    """Viagens de uma linha que ficaram fora de todos os grupos, em ordem de data."""
    viagens = dados.ler_viagens(inicio, fim, linha)
    if viagens.empty:
        raise ValueError(f"Sem viagens da linha {linha} entre {inicio} e {fim}.")
    marcadas = marcar_ruido(viagens)
    ruido = marcadas[marcadas["ruido"]].drop(columns=["grupo", "ruido"])
    return ruido.sort_values("inicio_realizado").reset_index(drop=True)

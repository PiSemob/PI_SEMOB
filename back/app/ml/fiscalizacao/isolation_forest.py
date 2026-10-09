# detecção de anomalia por casos raros 


"""Isolation Forest: aponta os dias em que uma linha fugiu do próprio padrão.

Cada registro é uma linha em um dia. O modelo dá uma pontuação de anomalia a cada
um e marca os mais raros. Ele aponta o que é estatisticamente atípico; quem diz se
é irregularidade é a SEMOB.
"""

from datetime import date

import pandas as pd
from sklearn.ensemble import IsolationForest

from app.ml import dados

VARIAVEIS = ["nr_viagens", "km_total", "km_por_viagem", "duracao_media", "nr_veiculos"]
CONTAMINACAO = 0.02
MINIMO_DE_DIAS = 30


def _desvios(valores: pd.Series) -> pd.Series:
    """Quantos desvios-padrão cada valor está da média do seu grupo."""
    desvio = valores.std(ddof=0)
    if desvio == 0:  
        return valores * 0.0
    return (valores - valores.mean()) / desvio


def pontuar(linha_dia: pd.DataFrame, contaminacao: float = CONTAMINACAO) -> pd.DataFrame:
    """Recebe a tabela por linha e dia e devolve a mesma tabela com três colunas novas.

    - `pontuacao`: quanto maior, mais atípico.
    - `atipico`: verdadeiro para os registros que o modelo marcou.
    - `destaque`: a variável que mais destoou e em quantos desvios.
    """
    dias_por_linha = linha_dia.groupby("linha")["data"].transform("nunique")
    tabela = linha_dia[dias_por_linha >= MINIMO_DE_DIAS].reset_index(drop=True)
    if tabela.empty:
        raise ValueError(f"Nenhuma linha com pelo menos {MINIMO_DE_DIAS} dias de operação.")
    desvios = tabela.groupby(["linha", "tipo_dia"])[VARIAVEIS].transform(_desvios)

    modelo = IsolationForest(n_estimators=300, contamination=contaminacao, random_state=42)
    modelo.fit(desvios)

    tabela["pontuacao"] = (-modelo.score_samples(desvios)).round(3)
    tabela["atipico"] = modelo.predict(desvios) == -1
    maior = desvios.abs().idxmax(axis=1)
    valor = [desvios.at[indice, coluna] for indice, coluna in maior.items()]
    tabela["destaque"] = [
        f"{coluna}: {abs(v):.1f} desvios {'acima' if v > 0 else 'abaixo'} do normal"
        for coluna, v in zip(maior, valor)
    ]
    return tabela.sort_values("pontuacao", ascending=False).reset_index(drop=True)


def dias_atipicos(inicio: date, fim: date, linha: str | None = None) -> pd.DataFrame:
    """Dias e linhas atípicos do período, do mais para o menos atípico.

    O modelo sempre aprende com todas as linhas do período. O parâmetro `linha`
    só filtra o que é devolvido.
    """
    viagens = dados.ler_viagens(inicio, fim)
    resultado = pontuar(dados.agregar_linha_dia(viagens))
    resultado = resultado[resultado["atipico"]]
    if linha is not None:
        resultado = resultado[resultado["linha"] == linha]
    return resultado.reset_index(drop=True)
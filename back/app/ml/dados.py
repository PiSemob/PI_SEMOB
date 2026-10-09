#consultas que montam as series e matrizes que serão ingeridas pelos modelos, separado do s modelos para lerem da mesma forma


"""Consultas que montam as tabelas e séries que os modelos recebem.

Fica separado dos modelos para os quatro lerem os dados do mesmo jeito.
As funções `ler_...` falam com o PostgreSQL. As outras só transformam tabelas,
e por isso podem ser testadas sem banco.
"""

from datetime import date

import pandas as pd
from sqlalchemy import func, select

from app.db import tabelas

SERIES = ("passageiros", "viagens", "km")


def _consultar(consulta) -> pd.DataFrame:
    from app.db.postgres import criar_engine

    with criar_engine().connect() as conexao:
        return pd.read_sql(consulta, conexao)


def ler_viagens(inicio: date, fim: date, linha: str | None = None) -> pd.DataFrame:
    """Viagens realizadas no período (as duas datas entram), uma linha por viagem."""
    t = tabelas.viagens
    consulta = select(
        t.c.data, t.c.linha, t.c.prefixo, t.c.sentido, t.c.fx_hor,
        t.c.inicio_realizado, t.c.duracao_min, t.c.km_total,
    ).where(t.c.data.between(inicio, fim))
    if linha is not None:
        consulta = consulta.where(t.c.linha == linha)
    viagens = _consultar(consulta)
    viagens["km_total"] = viagens["km_total"].astype(float)  # o banco devolve Decimal
    viagens["data"] = pd.to_datetime(viagens["data"])
    return viagens


def tipo_de_dia(datas: pd.Series) -> pd.Series:
    """Classifica cada data em 'util', 'sabado' ou 'domingo'."""
    dia = pd.to_datetime(datas).dt.dayofweek  # 0 = segunda ... 6 = domingo
    return dia.map(lambda d: "domingo" if d == 6 else "sabado" if d == 5 else "util")


def agregar_linha_dia(viagens: pd.DataFrame) -> pd.DataFrame:
    """Resume as viagens em um registro por linha e por dia de operação."""
    resumo = (
        viagens.groupby(["data", "linha"])
        .agg(
            nr_viagens=("km_total", "size"),
            km_total=("km_total", "sum"),
            duracao_media=("duracao_min", "mean"),
            nr_veiculos=("prefixo", "nunique"),
        )
        .reset_index()
    )
    resumo["km_por_viagem"] = resumo["km_total"] / resumo["nr_viagens"]
  
    resumo["tipo_dia"] = tipo_de_dia(resumo["data"])
    return resumo


def ler_linhas(minimo_de_dias: int = 1) -> list[str]:
    """Códigos das linhas com pelo menos `minimo_de_dias` dias de operação, em ordem."""
    t = tabelas.resumo_linha
    consulta = (
        select(t.c.linha)
        .group_by(t.c.linha)
        .having(func.count() >= minimo_de_dias)
        .order_by(t.c.linha)
    )
    return _consultar(consulta)["linha"].tolist()


def ler_serie(nome: str, linha: str | None = None) -> pd.DataFrame:
    """Série diária com as colunas `ds` (data) e `y` (valor), em ordem de data.

    - "passageiros": total do sistema. Não existe por linha.
    - "viagens" e "km": de uma linha, ou a soma de todas quando `linha` é None.
    """
    if nome not in SERIES:
        raise ValueError(f"Série desconhecida: {nome}. Use uma de {SERIES}.")
    if nome == "passageiros":
        if linha is not None:
            raise ValueError("A base só tem passageiros do sistema inteiro, não por linha.")
        t = tabelas.passageiros
        consulta = select(t.c.data.label("ds"), t.c.total.label("y"))
    else:
        t = tabelas.resumo_linha
        coluna = t.c.nr_viagens if nome == "viagens" else t.c.km_total
        consulta = select(t.c.data.label("ds"), func.sum(coluna).label("y")).group_by(t.c.data)
        if linha is not None:
            consulta = consulta.where(t.c.linha == linha)
    serie = _consultar(consulta.order_by("ds"))
    if serie.empty:
        raise ValueError(f"Sem dados para a série {nome}" + (f" da linha {linha}." if linha else "."))
    serie["ds"] = pd.to_datetime(serie["ds"])
    serie["y"] = serie["y"].astype(float)
    return serie
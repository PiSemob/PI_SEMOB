# rotas que o front ira consumir para indicadores


"""Rotas de indicadores: números que já estão no banco, sem modelo de ML."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.engine import Connection

from app.api.dependencias import obter_conexao, validar_periodo
from app.db import tabelas

rotas = APIRouter(prefix="/indicadores", tags=["indicadores"])

Conexao = Annotated[Connection, Depends(obter_conexao)]


def _dividir(numerador, denominador, casas: int = 4) -> float | None:
    """Divisão que devolve None quando não há denominador, em vez de dar erro."""
    if not numerador or not denominador:
        return None
    return round(float(numerador) / float(denominador), casas)


@rotas.get("/periodo")
def periodo(conexao: Conexao) -> dict:
    """Primeiro e último dia com dados. O front usa para posicionar o filtro de datas."""
    geral, passageiros = tabelas.resumo_geral, tabelas.passageiros
    operacao = conexao.execute(select(func.min(geral.c.data), func.max(geral.c.data))).one()
    demanda = conexao.execute(
        select(func.min(passageiros.c.data), func.max(passageiros.c.data))
    ).one()
    return {
        "operacao": {"inicio": operacao[0], "fim": operacao[1]},
        "passageiros": {"inicio": demanda[0], "fim": demanda[1]},
    }


@rotas.get("/resumo")
def resumo(inicio: date, fim: date, conexao: Conexao) -> dict:
    """Totais do período: viagens, quilometragem, passageiros e os índices derivados.

    O IPK só usa os dias que têm passageiros e quilometragem, porque os
    passageiros começam depois da operação na base.
    """
    validar_periodo(inicio, fim)
    geral, passageiros = tabelas.resumo_geral, tabelas.passageiros

    operacao = conexao.execute(
        select(
            func.count().label("dias"),
            func.sum(geral.c.nr_viagens_progr).label("programadas"),
            func.sum(geral.c.nr_viagens_realiz).label("realizadas"),
            func.sum(geral.c.km_prod).label("km_prod"),
            func.sum(geral.c.km_improd).label("km_improd"),
            func.sum(geral.c.km_total).label("km_total"),
        ).where(geral.c.data.between(inicio, fim))
    ).mappings().one()

    demanda = conexao.execute(
        select(
            func.count().label("dias"),
            func.sum(passageiros.c.catraca).label("catraca"),
            func.sum(passageiros.c.antecipados).label("antecipados"),
            func.sum(passageiros.c.nao_pagantes).label("nao_pagantes"),
            func.sum(passageiros.c.total).label("total"),
        ).where(passageiros.c.data.between(inicio, fim))
    ).mappings().one()

    km_com_passageiros = conexao.scalar(
        select(func.sum(geral.c.km_total)).where(
            geral.c.data.between(inicio, fim),
            geral.c.data.in_(select(passageiros.c.data)),
        )
    )

    return {
        "inicio": inicio,
        "fim": fim,
        "dias_com_operacao": operacao["dias"],
        "viagens_programadas": operacao["programadas"] or 0,
        "viagens_realizadas": operacao["realizadas"] or 0,
        "cumprimento": _dividir(operacao["realizadas"], operacao["programadas"]),
        "km_produtivo": float(operacao["km_prod"] or 0),
        "km_improdutivo": float(operacao["km_improd"] or 0),
        "km_total": float(operacao["km_total"] or 0),
        "parcela_km_improdutivo": _dividir(operacao["km_improd"], operacao["km_total"]),
        "dias_com_passageiros": demanda["dias"],
        "passageiros": demanda["total"] or 0,
        "passageiros_catraca": demanda["catraca"] or 0,
        "passageiros_antecipados": demanda["antecipados"] or 0,
        "passageiros_nao_pagantes": demanda["nao_pagantes"] or 0,
        "parcela_nao_pagantes": _dividir(demanda["nao_pagantes"], demanda["total"]),
        "ipk": _dividir(demanda["total"], km_com_passageiros, casas=3),
    }

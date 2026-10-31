# rotas que o front ira consumir para anomalias


"""Rota de anomalias: roda um dos dois modelos de fiscalização no período pedido."""

from datetime import date
from typing import Literal

from fastapi import APIRouter, HTTPException

from app.api.dependencias import tabela_para_json, validar_periodo
from app.ml.fiscalizacao import dbscan, isolation_forest

rotas = APIRouter(prefix="/anomalias", tags=["anomalias"])


@rotas.get("")
def anomalias(
    modelo: Literal["isolation_forest", "dbscan"],
    inicio: date,
    fim: date,
    linha: str | None = None,
) -> dict:
    """Dias atípicos por linha (isolation_forest) ou viagens atípicas de uma linha (dbscan).

    Um pedido que os dados não atendem, como período sem viagens ou linha com
    poucos dias, volta como erro 400 com a mensagem do modelo.
    """
    validar_periodo(inicio, fim)
    try:
        if modelo == "isolation_forest":
            resultado = isolation_forest.dias_atipicos(inicio, fim, linha)
        else:
            if linha is None:
                raise ValueError("O modelo dbscan analisa uma linha por vez: informe `linha`.")
            resultado = dbscan.viagens_atipicas(inicio, fim, linha)
    except ValueError as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro
    return {
        "modelo": modelo,
        "inicio": inicio,
        "fim": fim,
        "linha": linha,
        "quantidade": len(resultado),
        "anomalias": tabela_para_json(resultado),
    }

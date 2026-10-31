# rotas que o front ira consumir para previsoes


"""Rota de previsões: os próximos dias de uma série, com o modelo escolhido para ela."""

from typing import Annotated, Literal

from fastapi import APIRouter, HTTPException, Query

from app.ml.planejamento import previsao

rotas = APIRouter(prefix="/previsoes", tags=["previsoes"])


@rotas.get("")
def previsoes(
    alvo: Literal["passageiros", "viagens", "km"],
    linha: str | None = None,
    dias: Annotated[int, Query(ge=1, le=14)] = 7,
) -> dict:
    """Previsão com intervalo. Passageiros só existem para o sistema inteiro.

    Um pedido que os dados não atendem, como passageiros por linha, volta como
    erro 400 com a mensagem do modelo.
    """
    try:
        return previsao.prever(alvo, dias, linha)
    except ValueError as erro:
        raise HTTPException(status_code=400, detail=str(erro)) from erro

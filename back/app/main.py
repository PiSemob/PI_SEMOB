# registro de rotas api


from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import (
    anomalias,
    autenticacao,
    chat,
    configuracoes,
    indicadores,
    notificacoes,
    previsoes,
    relatorios,
    usuarios,
)

app = FastAPI(title="PI SEMOB")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition"],
)

app.include_router(indicadores.rotas)
app.include_router(anomalias.rotas)
app.include_router(previsoes.rotas)
app.include_router(autenticacao.rotas)
app.include_router(chat.rotas)
app.include_router(relatorios.rotas)
app.include_router(configuracoes.rotas)
app.include_router(notificacoes.rotas)
app.include_router(usuarios.rotas)


@app.get("/saude")
def saude() -> dict[str, str]:
    return {"status": "ok"}

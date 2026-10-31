# registro de rotas api


from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import anomalias, indicadores, previsoes

app = FastAPI(title="PI SEMOB")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(indicadores.rotas)
app.include_router(anomalias.rotas)
app.include_router(previsoes.rotas)


@app.get("/saude")
def saude() -> dict[str, str]:
    return {"status": "ok"}

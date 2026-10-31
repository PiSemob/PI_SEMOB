# registro de rotas api


from fastapi import FastAPI

from app.api import indicadores

app = FastAPI(title="PI SEMOB")

app.include_router(indicadores.rotas)


@app.get("/saude")
def saude() -> dict[str, str]:
    return {"status": "ok"}

# registro de rotas api


from fastapi import FastAPI

app = FastAPI(title="PI SEMOB")


@app.get("/saude")
def saude() -> dict[str, str]:
    return {"status": "ok"}
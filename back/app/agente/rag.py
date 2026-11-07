from functools import lru_cache

from app.db import vetorial


@lru_cache(maxsize=1)
def _indice() -> vetorial.IndiceDocumentos:
    return vetorial.carregar() or vetorial.construir()


def tem_documentos() -> bool:
    return bool(_indice().trechos)


def buscar(consulta: str, quantos: int = 3) -> list[dict]:
    return [{"documento": t.documento, "texto": t.texto} for t in _indice().buscar(consulta, quantos)]

from sqlalchemy.engine import Connection

from app.agente import rag
from app.agente.ferramentas.base import Limites, Resultado, indicador, tela


def buscar_documentos(conexao: Connection, limites: Limites, consulta) -> Resultado:
    trechos = rag.buscar(str(consulta)[:300])
    if trechos:
        nomes = ", ".join(sorted({t["documento"] for t in trechos}))
        texto = f"Documentos da SEMOB que tratam do assunto: {nomes}."
    else:
        texto = "Não encontrei nos documentos da SEMOB nada sobre isso."
    return Resultado(
        "buscar_documentos",
        {"consulta": consulta, "trechos": trechos},
        texto,
        tela("Documentos consultados", [indicador("Trechos encontrados", len(trechos))],
             ["Documento", "Trecho"], [[t["documento"], t["texto"][:240]] for t in trechos]),
    )

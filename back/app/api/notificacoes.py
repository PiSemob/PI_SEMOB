from datetime import date, timedelta
from functools import lru_cache
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.engine import Connection

from app import configuracoes
from app.api.dependencias import obter_conexao, usuario_atual
from app.autenticacao import Usuario
from app.db import tabelas
from app.formatos import data_br
from app.ml.fiscalizacao import isolation_forest

rotas = APIRouter(prefix="/notificacoes", tags=["notificacoes"])

Conexao = Annotated[Connection, Depends(obter_conexao)]
Logado = Annotated[Usuario, Depends(usuario_atual)]

JANELA_DIAS = 7
HISTORICO_DO_MODELO_DIAS = 30


@lru_cache(maxsize=4)
def _atipicos(inicio: date, fim: date) -> tuple[dict, ...]:
    tabela = isolation_forest.dias_atipicos(inicio - timedelta(days=HISTORICO_DO_MODELO_DIAS), fim)
    tabela = tabela[tabela["data"].dt.date >= inicio]
    return tuple(
        {"data": linha.data.date(), "linha": linha.linha,
         "destaque": ", ".join(linha.destaque) if isinstance(linha.destaque, list) else str(linha.destaque or "")}
        for linha in tabela.itertuples()
    )


def _aviso_de_anomalia(atipico: dict) -> dict:
    return {
        "id": f"atipico-{atipico['data']}-{atipico['linha']}",
        "tipo": "anomalia",
        "titulo": f"Linha {atipico['linha']} fora do padrão em {data_br(atipico['data'])}",
        "texto": atipico["destaque"] or "Apontado pelo Isolation Forest.",
        "data": atipico["data"].isoformat(),
        "rota": "/operacao?aba=frota",
    }


def _aviso_de_nao_realizadas(dia: date, quantidade: int) -> dict:
    plural = quantidade > 1
    return {
        "id": f"nao-realizadas-{dia}",
        "tipo": "operacao",
        "titulo": f"{quantidade} viage{'ns' if plural else 'm'} não realizada{'s' if plural else ''} em {data_br(dia)}",
        "texto": "Pergunte ao Ferret Jr: \"Quais viagens não foram realizadas?\"",
        "data": dia.isoformat(),
        "rota": "/assistente",
    }


def montar(conexao: Connection) -> list[dict]:
    ultimo = conexao.scalar(select(func.max(tabelas.resumo_geral.c.data)))
    if ultimo is None:
        return []
    inicio = ultimo - timedelta(days=JANELA_DIAS - 1)
    avisos = []
    if configuracoes.ler(conexao)["alertas_anomalia"]:
        avisos += [_aviso_de_anomalia(a) for a in _atipicos(inicio, ultimo)]
    t = tabelas.viagens_excecao
    nao_realizadas = conexao.execute(
        select(t.c.data, func.count())
        .where(t.c.data.between(inicio, ultimo), t.c.situacao == "nao_realizada")
        .group_by(t.c.data)
    ).all()
    avisos += [_aviso_de_nao_realizadas(dia, quantidade) for dia, quantidade in nao_realizadas]
    return sorted(avisos, key=lambda a: a["data"], reverse=True)


@rotas.get("")
def notificacoes(usuario: Logado, conexao: Conexao) -> dict:
    avisos = montar(conexao)
    return {"quantidade": len(avisos), "notificacoes": avisos}

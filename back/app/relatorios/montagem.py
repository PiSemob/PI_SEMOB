import logging
import re
from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.engine import Connection

from app import configuracoes
from app.agente import tools
from app.agente.ferramentas.base import Limites, Resultado, ler_limites
from app.api import indicadores
from app.db import tabelas
from app.formatos import data_br, periodo_br

log = logging.getLogger(__name__)

MODELOS = {
    "executivo": "Relatório Executivo",
    "operacional": "Relatório Operacional",
    "financeiro": "Relatório Financeiro",
    "prestacao_contas": "Prestação de Contas",
}

SECOES = {
    "executivo": (
        ("Visão geral da operação", "resumo_operacao"),
        ("Linhas", "viagens_por_linha"),
        ("Demanda", "passageiros_por_dia"),
        ("Créditos", "creditos"),
        ("Pontos de atenção (Isolation Forest)", "dias_atipicos"),
        ("Viagens com problema", "viagens_com_problema"),
    ),
    "operacional": (
        ("Visão geral da operação", "resumo_operacao"),
        ("Viagens por linha", "viagens_por_linha"),
        ("Horário de pico", "partidas_por_faixa_horaria"),
        ("Viagens com problema", "viagens_com_problema"),
        ("Dias atípicos (Isolation Forest)", "dias_atipicos"),
    ),
    "financeiro": (
        ("Venda e utilização de créditos", "creditos"),
        ("Passageiros e gratuidade", "passageiros_por_dia"),
    ),
    "prestacao_contas": (
        ("Visão geral da operação", "resumo_operacao"),
        ("Viagens não cumpridas", "viagens_com_problema"),
    ),
}

PREVISOES = {
    "executivo": (("Próximos 7 dias", "passageiros"),),
    "operacional": (("Previsão de viagens (7 dias)", "viagens"), ("Previsão de km (7 dias)", "km")),
}

def _secao(titulo: str, texto: str, tela: dict) -> dict:
    return {"titulo": titulo, "texto": texto, "indicadores": tela.get("indicadores", []), "tabela": tela.get("tabela")}


def _rodar(nome: str, argumentos: dict, conexao: Connection, limites: Limites) -> Resultado | None:
    try:
        return tools.executar(nome, argumentos, conexao, limites)
    except ValueError as erro:
        log.info("seção %s sem dados: %s", nome, erro)
        return None


def _diario(conexao: Connection, inicio: date, fim: date) -> dict:
    dias = indicadores.diario(inicio, fim, conexao)
    return {
        "colunas": ["Data", "Veículos", "Programadas", "Realizadas", "Cumprimento (%)", "Km total", "Passageiros"],
        "linhas": [
            [data_br(d["data"]), d["nr_veiculos"], d["viagens_programadas"], d["viagens_realizadas"],
             round(100 * d["viagens_realizadas"] / d["viagens_programadas"], 2) if d["viagens_programadas"] else None,
             round(d["km_total"] or 0, 1), d["passageiros"]]
            for d in dias
        ],
    }


def _fontes(conexao: Connection, inicio: date, fim: date) -> dict:
    arquivos: dict[str, datetime] = {}
    for tabela in (tabelas.resumo_geral, tabelas.resumo_linha, tabelas.passageiros, tabelas.vendas,
                   tabelas.viagens_excecao):
        consulta = select(tabela.c.arquivo_origem, tabela.c.gerado_em).where(tabela.c.data.between(inicio, fim))
        for arquivo, gerado in conexao.execute(consulta.distinct()):
            arquivos[arquivo] = gerado
    return {
        "colunas": ["Arquivo do Smart Report", "Gerado em"],
        "linhas": [[a, g.strftime("%d/%m/%Y %H:%M") if g else ""] for a, g in sorted(arquivos.items())],
    }


def _saldos(conexao: Connection, inicio: date, fim: date) -> dict | None:
    saldos = indicadores.creditos(inicio, fim, conexao)["saldos"]
    if not saldos:
        return None
    ultimo = max(s["data"] for s in saldos)
    return _secao(
        f"Saldo por série em {data_br(ultimo)}", "",
        {"indicadores": [], "tabela": {
            "colunas": ["Série", "Créditos transferidos (R$)", "Saldo final (R$)"],
            "linhas": [[s["serie"], s["creditos_transferidos"], s["saldo_final"]] for s in saldos if s["data"] == ultimo],
        }},
    )


def _secoes(modelo: str, conexao: Connection, limites: Limites, inicio: date, fim: date) -> list[dict]:
    periodo = {"inicio": inicio.isoformat(), "fim": fim.isoformat()}
    secoes = []
    for titulo, ferramenta in SECOES[modelo]:
        resultado = _rodar(ferramenta, periodo, conexao, limites)
        if resultado:
            secoes.append(_secao(titulo, resultado.texto, resultado.tela))
    for titulo, alvo in PREVISOES.get(modelo, ()):
        resultado = _rodar("prever", {"alvo": alvo, "dias": 7}, conexao, limites)
        if resultado:
            secoes.append(_secao(titulo, resultado.texto, resultado.tela))
    if modelo == "operacional":
        secoes.append(_secao("Operação dia a dia", "", {"tabela": _diario(conexao, inicio, fim)}))
    if modelo == "financeiro":
        saldos = _saldos(conexao, inicio, fim)
        if saldos:
            secoes.append(saldos)
    if modelo == "prestacao_contas":
        secoes.append(_secao("Cumprimento dia a dia", "", {"tabela": _diario(conexao, inicio, fim)}))
        secoes.append(_secao(
            "Origem dos dados",
            "Todos os números deste relatório vêm dos arquivos abaixo, exportados pelo Smart Report e carregados "
            "sem alteração no banco. Registros fora do comum são sinalizados como suspeitos, não apagados.",
            {"tabela": _fontes(conexao, inicio, fim)},
        ))
    return secoes


def _primeira_frase(texto: str) -> str:
    achado = re.search(r"\.(\s|$)", texto)
    return texto[: achado.start() + 1] if achado else texto


def _resumo(titulo: str, inicio: date, fim: date, secoes: list[dict]) -> str:
    destaques = " ".join(_primeira_frase(s["texto"]) for s in secoes[:5] if s["texto"])
    return f"Este {titulo.lower()} cobre o período {periodo_br(inicio, fim)}. {destaques}"


def montar(modelo: str, inicio: date, fim: date, conexao: Connection) -> dict:
    if modelo not in MODELOS:
        raise ValueError(f"Modelo de relatório desconhecido: {modelo}.")
    if inicio > fim:
        raise ValueError("A data de início é depois da data de fim.")
    limites = ler_limites(conexao)
    if limites is None:
        raise ValueError("Ainda não há dados carregados no sistema.")
    ajustes = configuracoes.ler(conexao)
    titulo = MODELOS[modelo]
    secoes = _secoes(modelo, conexao, limites, inicio, fim)
    if not secoes:
        raise ValueError("Não há dados no período escolhido.")

    return {
        "modelo": modelo,
        "titulo": titulo,
        "organizacao": ajustes["organizacao"],
        "cidade": ajustes["cidade"],
        "inicio": inicio.isoformat(),
        "fim": fim.isoformat(),
        "gerado_em": datetime.now().isoformat(timespec="seconds"),
        "resumo": _resumo(titulo, inicio, fim, secoes),
        "secoes": secoes,
    }


def dados_diarios(conexao: Connection, inicio: date, fim: date) -> tuple[list[str], list[list]]:
    vendas = {v["data"]: v for v in indicadores.creditos(inicio, fim, conexao)["vendas"]}
    colunas = ["data", "veiculos", "viagens_programadas", "viagens_realizadas", "km_total",
               "passageiros", "passageiros_nao_pagantes", "vendas_creditos", "utilizacao_creditos"]
    linhas = []
    for d in indicadores.diario(inicio, fim, conexao):
        venda = vendas.get(d["data"], {})
        linhas.append([d["data"].isoformat(), d["nr_veiculos"], d["viagens_programadas"], d["viagens_realizadas"],
                       d["km_total"], d["passageiros"], d["passageiros_nao_pagantes"],
                       venda.get("total_vendas"), venda.get("total_utilizacao")])
    return colunas, linhas

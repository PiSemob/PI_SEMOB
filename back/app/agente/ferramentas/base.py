from dataclasses import dataclass
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.engine import Connection

from app.db import tabelas
from app.formatos import data_br, para_data

MAXIMO_DE_DIAS = 400


@dataclass
class Resultado:
    ferramenta: str
    dados: dict
    texto: str
    tela: dict


@dataclass(frozen=True)
class Limites:
    primeiro: date
    ultimo: date
    linhas: tuple[str, ...]


def ler_limites(conexao: Connection) -> Limites | None:
    geral = tabelas.resumo_geral
    primeiro, ultimo = conexao.execute(select(func.min(geral.c.data), func.max(geral.c.data))).one()
    if primeiro is None:
        return None
    linha = tabelas.resumo_linha.c.linha
    linhas = tuple(conexao.scalars(select(linha).distinct().order_by(linha)))
    return Limites(primeiro, ultimo, linhas)


def validar_periodo(inicio, fim, limites: Limites, maximo_dias: int = MAXIMO_DE_DIAS) -> tuple[date, date]:
    try:
        inicio, fim = para_data(inicio), para_data(fim)
    except ValueError as erro:
        raise ValueError("Data inválida. Use o formato AAAA-MM-DD.") from erro
    if inicio > fim:
        raise ValueError("A data de início é depois da data de fim.")
    if fim < limites.primeiro or inicio > limites.ultimo:
        raise ValueError(
            f"Não há dados nesse período. A base vai de {data_br(limites.primeiro)} a {data_br(limites.ultimo)}."
        )
    inicio, fim = max(inicio, limites.primeiro), min(fim, limites.ultimo)
    if (fim - inicio).days + 1 > maximo_dias:
        raise ValueError(f"Para esta análise, use um período de até {maximo_dias} dias.")
    return inicio, fim


def validar_linha(linha, limites: Limites) -> str | None:
    if linha in (None, ""):
        return None
    codigo = str(linha).strip()
    codigo = codigo.zfill(2) if codigo.isdigit() else codigo
    if codigo not in limites.linhas:
        raise ValueError(f"A linha {codigo} não existe na base. Linhas: {', '.join(limites.linhas)}.")
    return codigo


def indicador(nome: str, valor, unidade: str = "") -> dict:
    return {"nome": nome, "valor": valor, "unidade": unidade}


def tela(titulo: str, indicadores: list[dict], colunas: list[str] | None = None,
         linhas: list[list] | None = None) -> dict:
    tabela = {"colunas": colunas, "linhas": linhas} if colunas is not None else None
    return {"titulo": titulo, "indicadores": indicadores, "tabela": tabela}

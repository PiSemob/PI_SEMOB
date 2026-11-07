from collections.abc import Callable
from dataclasses import dataclass

from sqlalchemy.engine import Connection

from app.agente.ferramentas import consultas, documentos, modelos
from app.agente.ferramentas.base import Limites, Resultado

PERIODO = ("inicio", "fim")


@dataclass(frozen=True)
class Ferramenta:
    nome: str
    parametros: tuple[str, ...]
    obrigatorios: tuple[str, ...]
    funcao: Callable[..., Resultado]


FERRAMENTAS: dict[str, Ferramenta] = {
    f.nome: f
    for f in (
        Ferramenta("sobre_os_dados", (), (), consultas.sobre_os_dados),
        Ferramenta("resumo_operacao", PERIODO, PERIODO, consultas.resumo_operacao),
        Ferramenta("comparar_periodos", ("inicio_a", "fim_a", "inicio_b", "fim_b"),
                   ("inicio_a", "fim_a", "inicio_b", "fim_b"), consultas.comparar_periodos),
        Ferramenta("viagens_por_linha", PERIODO, PERIODO, consultas.viagens_por_linha),
        Ferramenta("passageiros_por_dia", PERIODO, PERIODO, consultas.passageiros_por_dia),
        Ferramenta("partidas_por_faixa_horaria", (*PERIODO, "linha"), PERIODO, consultas.partidas_por_faixa_horaria),
        Ferramenta("viagens_com_problema", (*PERIODO, "situacao"), PERIODO, consultas.viagens_com_problema),
        Ferramenta("creditos", PERIODO, PERIODO, consultas.creditos),
        Ferramenta("dias_atipicos", (*PERIODO, "linha"), PERIODO, modelos.dias_atipicos),
        Ferramenta("viagens_atipicas", (*PERIODO, "linha"), (*PERIODO, "linha"), modelos.viagens_atipicas),
        Ferramenta("prever", ("alvo", "linha", "dias"), ("alvo",), modelos.prever),
        Ferramenta("buscar_documentos", ("consulta",), ("consulta",), documentos.buscar_documentos),
    )
}


def executar(nome: str, argumentos: dict, conexao: Connection, limites: Limites) -> Resultado:
    ferramenta = FERRAMENTAS.get(nome)
    if ferramenta is None:
        raise ValueError(f"Ferramenta desconhecida: {nome}.")
    if not isinstance(argumentos, dict):
        raise TypeError("Argumentos inválidos.")
    desconhecidos = set(argumentos) - set(ferramenta.parametros)
    if desconhecidos:
        raise ValueError(f"Parâmetros não aceitos: {', '.join(sorted(desconhecidos))}.")
    faltando = [p for p in ferramenta.obrigatorios if argumentos.get(p) in (None, "")]
    if faltando:
        raise ValueError(f"Faltam parâmetros: {', '.join(faltando)}.")
    validos = {chave: valor for chave, valor in argumentos.items() if valor is not None}
    return ferramenta.funcao(conexao, limites, **validos)

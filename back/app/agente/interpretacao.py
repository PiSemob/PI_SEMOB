import calendar
import re
from dataclasses import dataclass, field
from datetime import date, timedelta

from app.texto import normalizar

MESES = {
    "janeiro": 1, "fevereiro": 2, "marco": 3, "abril": 4, "maio": 5, "junho": 6, "julho": 7,
    "agosto": 8, "setembro": 9, "outubro": 10, "novembro": 11, "dezembro": 12,
}
PADRAO_DIAS = 30
SEM_PASSAGEIRO_POR_LINHA = "A base só tem passageiros do sistema inteiro, então mostrei o total do sistema."
FERRAMENTAS_COM_LINHA = ("partidas_por_faixa_horaria", "dias_atipicos", "viagens_atipicas", "prever")


@dataclass
class Pedido:
    ferramenta: str
    argumentos: dict = field(default_factory=dict)
    periodo_explicito: bool = False
    observacao: str = ""


def extrair_linha(texto: str) -> str | None:
    achado = re.search(r"linha\s*(?:n[ºo°.]?\s*)?(\d{1,2})\b", texto)
    return achado.group(1).zfill(2) if achado else None


def _limitar(inicio: date, fim: date, primeiro: date, ultimo: date) -> tuple[date, date]:
    return max(inicio, primeiro), min(fim, ultimo)


def _ano_do_mes(mes: int, ultimo: date) -> int:
    return ultimo.year if mes <= ultimo.month else ultimo.year - 1


def _mes_inteiro(mes: int, primeiro: date, ultimo: date) -> tuple[date, date]:
    ano = _ano_do_mes(mes, ultimo)
    return _limitar(date(ano, mes, 1), date(ano, mes, calendar.monthrange(ano, mes)[1]), primeiro, ultimo)


def meses_citados(texto: str) -> list[int]:
    return [MESES[m] for m in re.findall(r"\b(" + "|".join(MESES) + r")\b", texto)]


def extrair_periodo(texto: str, primeiro: date, ultimo: date) -> tuple[date, date] | None:
    datas = []
    for dia, mes, ano in re.findall(r"\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b", texto)[:2]:
        ano_completo = (int(ano) + (2000 if len(ano) == 2 else 0)) if ano else ultimo.year
        try:
            datas.append(date(ano_completo, int(mes), int(dia)))
        except ValueError:
            continue
    if datas:
        return min(datas), max(datas)

    meses = meses_citados(texto)
    if meses:
        inicio, _ = _mes_inteiro(min(meses), primeiro, ultimo)
        _, fim = _mes_inteiro(max(meses), primeiro, ultimo)
        return inicio, fim

    quantos = re.search(r"ultim[oa]s\s+(\d{1,3})\s+dias", texto)
    if quantos:
        return _limitar(ultimo - timedelta(days=int(quantos.group(1)) - 1), ultimo, primeiro, ultimo)
    relativos = (
        (r"ultima semana|semana passada|ultimos sete dias|esta semana|nesta semana", 7),
        (r"ultima quinzena|quinzena passada", 15),
        (r"ultimo mes|mes passado|ultimos trinta dias|este mes|neste mes", 30),
    )
    for padrao, dias in relativos:
        if re.search(padrao, texto):
            return _limitar(ultimo - timedelta(days=dias - 1), ultimo, primeiro, ultimo)
    if re.search(r"\bontem\b|\bhoje\b|ultimo dia", texto):
        return ultimo, ultimo
    if re.search(r"todo o periodo|base (toda|inteira)|desde o inicio|no total", texto):
        return primeiro, ultimo
    return None


def _periodo_padrao(primeiro: date, ultimo: date) -> tuple[date, date]:
    return _limitar(ultimo - timedelta(days=PADRAO_DIAS - 1), ultimo, primeiro, ultimo)


def extrair_alvo(texto: str) -> str:
    if re.search(r"passageir|demanda|pessoas", texto):
        return "passageiros"
    if re.search(r"\bkm\b|quilometr", texto):
        return "km"
    return "viagens"


def extrair_dias(texto: str) -> int:
    achado = re.search(r"(\d{1,2})\s*dias", texto)
    if achado:
        return max(1, min(int(achado.group(1)), 14))
    if re.search(r"\bamanha\b", texto):
        return 1
    if re.search(r"quinzena|duas semanas", texto):
        return 14
    return 7


def _consulta(texto: str) -> str:
    regras = (
        (r"periodo (dos|de) dados|quais (sao os )?dados|ate quando|desde quando|ultima atualizacao|quais linhas existem",
         "sobre_os_dados"),
        (r"nao (foram )?(realizad|iniciad|terminad)|nao cumprid|perdid|falh|cancelad|problema", "viagens_com_problema"),
        (r"horari|faixa|\bpico\b|\bhora\b|partida", "partidas_por_faixa_horaria"),
        (r"credit|venda|utilizac|saldo|bilhet|receita|arrecad|dinheiro|r\$", "creditos"),
        (r"(qual|quais|que) linhas?|por linha|cada linha|ranking|linhas? (que|com) (mais|menos)", "viagens_por_linha"),
    )
    for padrao, ferramenta in regras:
        if re.search(padrao, texto):
            return ferramenta
    if re.search(r"passageir|demanda|pagante|gratuid|catraca|antecipad", texto) and not re.search(r"\bipk\b", texto):
        return "passageiros_por_dia"
    return "resumo_operacao"


def _comparacao(texto: str, primeiro: date, ultimo: date) -> Pedido:
    meses = list(dict.fromkeys(meses_citados(texto)))
    if len(meses) >= 2:
        a, b = sorted(meses[:2], key=lambda m: (_ano_do_mes(m, ultimo), m))
        inicio_a, fim_a = _mes_inteiro(a, primeiro, ultimo)
        inicio_b, fim_b = _mes_inteiro(b, primeiro, ultimo)
    else:
        inicio_b, fim_b = extrair_periodo(texto, primeiro, ultimo) or _periodo_padrao(primeiro, ultimo)
        if len(meses) == 1:
            fim_a = inicio_b - timedelta(days=1)
            inicio_a = fim_a.replace(day=1)
        else:
            duracao = fim_b - inicio_b
            fim_a = inicio_b - timedelta(days=1)
            inicio_a = fim_a - duracao
    return Pedido(
        "comparar_periodos",
        {"inicio_a": inicio_a.isoformat(), "fim_a": fim_a.isoformat(),
         "inicio_b": inicio_b.isoformat(), "fim_b": fim_b.isoformat()},
        True,
    )


def interpretar(opcao: str, mensagem: str, primeiro: date, ultimo: date) -> Pedido:
    texto = normalizar(mensagem)
    linha = extrair_linha(texto)

    if opcao == "previsao":
        argumentos = {"alvo": extrair_alvo(texto), "dias": extrair_dias(texto)}
        if linha and argumentos["alvo"] == "passageiros":
            return Pedido("prever", argumentos, True, SEM_PASSAGEIRO_POR_LINHA)
        if linha:
            argumentos["linha"] = linha
        return Pedido("prever", argumentos, True)
    if opcao == "comparacao":
        return _comparacao(texto, primeiro, ultimo)

    periodo = extrair_periodo(texto, primeiro, ultimo)
    explicito = periodo is not None
    inicio, fim = periodo or _periodo_padrao(primeiro, ultimo)
    datas = {"inicio": inicio.isoformat(), "fim": fim.isoformat()}

    if opcao == "dbscan":
        return Pedido("viagens_atipicas", {**datas, "linha": linha}, explicito)
    if opcao == "isolation_forest":
        return Pedido("dias_atipicos", {**datas, "linha": linha}, explicito)

    ferramenta = _consulta(texto)
    if ferramenta == "sobre_os_dados":
        return Pedido(ferramenta, {}, True)
    argumentos = dict(datas)
    if ferramenta == "partidas_por_faixa_horaria":
        argumentos["linha"] = linha
    if ferramenta == "viagens_com_problema":
        for situacao, padrao in (("nao_realizada", "realizad"), ("nao_iniciada", "iniciad"), ("nao_terminada", "terminad")):
            if re.search(r"nao (foram )?" + padrao, texto):
                argumentos["situacao"] = situacao
                break
    return Pedido(ferramenta, argumentos, explicito)


def seguimento(mensagem: str, anterior: str, opcao_anterior: str, primeiro: date, ultimo: date) -> Pedido | None:
    texto = normalizar(mensagem)
    periodo = extrair_periodo(texto, primeiro, ultimo)
    linha = extrair_linha(texto)
    if periodo is None and linha is None:
        return None
    pedido = interpretar(opcao_anterior, anterior, primeiro, ultimo)
    if periodo is not None and "inicio" in pedido.argumentos:
        pedido.argumentos.update(inicio=periodo[0].isoformat(), fim=periodo[1].isoformat())
        pedido.periodo_explicito = True
    sem_passageiro_por_linha = pedido.argumentos.get("alvo") != "passageiros"
    if linha is not None and pedido.ferramenta in FERRAMENTAS_COM_LINHA and sem_passageiro_por_linha:
        pedido.argumentos["linha"] = linha
    return pedido

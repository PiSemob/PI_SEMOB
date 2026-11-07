import re
from dataclasses import dataclass

from app.texto import normalizar

OPCOES = ("consulta", "comparacao", "isolation_forest", "dbscan", "previsao", "conversa", "fora_do_escopo")

FORA = (
    r"previsao do tempo", r"\bclima\b", r"\bchuv", r"\bfutebol", r"\bjogo d[oa]\b", r"\breceita de\b",
    r"\bpiada", r"\bfilme", r"\bmusica", r"\bhoroscopo", r"\bbitcoin", r"\bacoes da bolsa", r"\bpolitic",
    r"\beleic", r"\bcodigo (em|de) (python|java)", r"\bescreva (um|uma) (poema|historia|redacao)",
)
DOMINIO = (
    r"viage", r"\blinha", r"passageir", r"\bkm\b", r"quilometr", r"credit", r"venda", r"frota", r"onibus",
    r"veicul", r"demanda", r"cumpriment", r"horari", r"faixa", r"pico", r"pagante", r"gratuid", r"saldo",
    r"\bipk\b", r"operac", r"anomal", r"atipic", r"estranh", r"irregular", r"suspeit", r"fraude", r"previs",
    r"prever", r"proxim", r"semob", r"tarifa", r"catraca", r"realizad", r"iniciad", r"terminad", r"utilizac",
    r"bilhet", r"indicador", r"resumo", r"dados", r"periodo", r"receita", r"arrecad", r"partida",
)
ANOMALIA = (r"anomal", r"atipic", r"estranh", r"fora do padrao", r"irregular", r"suspeit", r"fraude",
            r"isolation", r"dbscan", r"desvio")
PREVISAO = (r"previs", r"prever", r"proxim", r"semana que vem", r"\bamanha\b", r"\bvai ter\b", r"\bvao ter\b",
            r"esperar", r"futuro", r"prophet", r"sarimax", r"projec", r"estimativ")
COMPARACAO = (r"compar", r"\bversus\b", r"\bvs\.?\b", r"em relacao a", r"\bfrente a", r"diferenca entre",
              (r"\b(cresceu|cresceram|caiu|cairam|aumentou|aumentaram|diminuiu|diminuiram|melhorou|"
               r"melhoraram|piorou|pioraram)\b"))
MESES = r"\b(janeiro|fevereiro|marco|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\b"
CONVERSA = (r"^o que (e|significa)\b", r"^como funciona", r"^expli", r"^por ?que\b", r"^obrigad", r"^valeu\b")


@dataclass(frozen=True)
class Decisao:
    opcao: str
    confianca: float


def _tem(texto: str, padroes) -> bool:
    return any(re.search(p, texto) for p in padroes)


def decidir(mensagem: str) -> Decisao:
    texto = normalizar(mensagem)
    if not texto:
        return Decisao("conversa", 0.5)
    if _tem(texto, FORA):
        return Decisao("fora_do_escopo", 0.9)
    if _tem(texto, CONVERSA) and not re.search(r"\b(quant|qual|quais)\b", texto):
        return Decisao("conversa", 0.7)
    if _tem(texto, PREVISAO):
        return Decisao("previsao", 0.85)
    if _tem(texto, ANOMALIA):
        de_viagem = _tem(texto, (r"dbscan",)) or (_tem(texto, (r"viage",)) and _tem(texto, (r"linha\s*\d",)))
        return Decisao("dbscan" if de_viagem else "isolation_forest", 0.8)
    if _tem(texto, COMPARACAO) and (_tem(texto, DOMINIO) or len(re.findall(MESES, texto)) >= 2):
        return Decisao("comparacao", 0.8)
    if _tem(texto, DOMINIO):
        return Decisao("consulta", 0.8)
    return Decisao("fora_do_escopo", 0.5)

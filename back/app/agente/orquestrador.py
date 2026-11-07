import logging
from dataclasses import dataclass, field

from sqlalchemy.engine import Connection

from app.agente import ajuda, intencao, interpretacao, rag, seguranca, tools
from app.agente.ferramentas.base import Limites, ler_limites
from app.texto import normalizar

log = logging.getLogger(__name__)

INICIOS_DE_CONTINUACAO = ("e ", "e no", "e na", "e em", "e para", "e pra", "e a ", "e o ", "e os ", "e as ")


@dataclass
class Resposta:
    texto: str
    decisao: dict
    dados: list[dict] = field(default_factory=list)


def _decisao(opcao: str, origem: str, ferramentas: list[str] | None = None, **extra) -> dict:
    return {"opcao": opcao, "origem": origem, "ferramentas": ferramentas or [], **extra}


def responder(mensagem: str, historico: list[dict], conexao: Connection) -> Resposta:
    mensagem = seguranca.limpar_entrada(mensagem)
    if not mensagem:
        return Resposta(ajuda.CAPACIDADES, _decisao("conversa", "regras"))
    resposta_de_ajuda = ajuda.responder(mensagem)
    if resposta_de_ajuda:
        return Resposta(resposta_de_ajuda, _decisao("ajuda", "regras"))
    bloqueio = seguranca.bloqueio(mensagem) or seguranca.pede_alteracao(mensagem)
    if bloqueio:
        log.warning("pedido recusado (%s)", bloqueio.motivo)
        return Resposta(bloqueio.resposta, _decisao("recusado", "seguranca", motivo=bloqueio.motivo))
    limites = ler_limites(conexao)
    if limites is None:
        return Resposta("Ainda não há dados carregados no sistema.", _decisao("consulta", "regras"))
    return _por_regras(mensagem, historico, limites, conexao)


def _ultima_pergunta(historico: list[dict]) -> str | None:
    return next((m["texto"] for m in reversed(historico) if m.get("papel") == "usuario"), None)


def _continuacao(mensagem: str, decisao: intencao.Decisao, historico: list[dict], limites: Limites):
    texto = normalizar(mensagem)
    parece = texto.startswith(INICIOS_DE_CONTINUACAO) or decisao.confianca <= 0.5
    anterior = _ultima_pergunta(historico)
    if not (parece or decisao.opcao in ("conversa", "fora_do_escopo")) or not anterior or len(texto.split()) > 8:
        return None
    decisao_anterior = intencao.decidir(anterior)
    if decisao_anterior.opcao in ("conversa", "fora_do_escopo"):
        return None
    pedido = interpretacao.seguimento(mensagem, anterior, decisao_anterior.opcao, limites.primeiro, limites.ultimo)
    return (decisao_anterior, pedido) if pedido else None


def _por_regras(mensagem: str, historico: list[dict], limites: Limites, conexao: Connection) -> Resposta:
    decisao = intencao.decidir(mensagem)
    continuacao = _continuacao(mensagem, decisao, historico, limites)
    if continuacao:
        decisao, pedido = continuacao
    elif decisao.opcao == "fora_do_escopo":
        return Resposta(ajuda.FORA_DO_ESCOPO, _decisao(decisao.opcao, "regras"))
    elif decisao.opcao == "conversa":
        return Resposta(ajuda.CAPACIDADES, _decisao(decisao.opcao, "regras"))
    else:
        pedido = interpretacao.interpretar(decisao.opcao, mensagem, limites.primeiro, limites.ultimo)

    if pedido.ferramenta == "viagens_atipicas" and not pedido.argumentos.get("linha"):
        return Resposta(
            "Para procurar viagens atípicas, preciso saber a linha. Exemplo: "
            "\"Tem viagem estranha na linha 04 em agosto?\"",
            _decisao(decisao.opcao, "regras"),
        )
    try:
        resultado = tools.executar(pedido.ferramenta, pedido.argumentos, conexao, limites)
    except ValueError as erro:
        return Resposta(f"Não consegui atender esse pedido: {erro}",
                        _decisao(decisao.opcao, "regras", [pedido.ferramenta]))

    texto = f"{resultado.texto} {pedido.observacao}".strip()
    if not pedido.periodo_explicito:
        texto += " Como a pergunta não citou período, usei os últimos 30 dias com dados."
    dados = [resultado.tela]
    anomalia = resultado.ferramenta in ("dias_atipicos", "viagens_atipicas") and resultado.dados["quantidade"]
    if anomalia and rag.tem_documentos():
        documentos = tools.executar("buscar_documentos", {"consulta": f"{mensagem} irregularidade"}, conexao, limites)
        if documentos.dados["trechos"]:
            texto += f" {documentos.texto}"
            dados.append(documentos.tela)
    return Resposta(texto, _decisao(decisao.opcao, "regras", [pedido.ferramenta], argumentos=pedido.argumentos),
                    dados)


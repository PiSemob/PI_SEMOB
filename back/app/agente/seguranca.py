import re
import time
from collections import defaultdict, deque
from collections.abc import Callable
from dataclasses import dataclass
from threading import Lock

from app.texto import normalizar

TAMANHO_MAXIMO = 1000
TAMANHO_MAXIMO_DA_RESPOSTA = 3000
CARACTERES_DE_CONTROLE = re.compile(r"[\x00-\x08\x0b-\x1f\x7f\u200b-\u200f\u2028-\u202e\ufeff]")

MANIPULACAO = (
    r"\b(ignor|desconsider|esquec)\w* (as |todas as |suas |essas |estas )?(instruc|regra|orienta|restric)",
    r"\b(prompt|instrucoes|regras) (do sistema|de sistema|internas|iniciais|originais)\b",
    r"\bsystem prompt\b",
    r"\b(revel|mostr|repit|imprim|copi)\w* (o |as |os |suas |seus )?(prompt|instruc|regras|configurac)",
    r"\b(jailbreak|modo desenvolvedor|developer mode|modo dan)\b",
    r"\b(finja|faca de conta|aja como|voce agora e|a partir de agora voce|esqueca quem voce e)\b",
    r"<\s*/?\s*(system|script|assistant)\b",
    r"\b(drop|truncate|alter)\s+table\b",
    r"\bdelete\s+from\b|\binsert\s+into\b|\bupdate\s+\w+\s+set\b|\bselect\s+.+\s+from\s+\w+",
)

DADO_SENSIVEL = (
    (r"\b(senha|token|chave|api ?key|credencia\w*|segredo|\.env)s?\b.*\bd[aeo]s? (usuario|banco|servidor|admin|"
     r"outr\w*|api|smtp)"),
    (r"\b(qual|quais|me (de|da|passa|mostra|envia|diga)|liste|listar|mostre|informe)\b.*\b(senha|token|chave|"
     r"credencia\w*)\b"),
    r"\b(conversa|historico|mensage)\w* d[aeo]s? (outr|demais)\w*",
    r"\b(lista|liste|quais sao|quem sao)\b.*\b(usuarios|funcionarios cadastrados|e-?mails cadastrados)\b",
    r"\b(cpf|rg|endereco|telefone) d[eo]s? (motorista|funcionario|usuario)",
)

ALTERACAO = (
    r"\b(apague|apagar|delete|deletar|exclua|excluir|remova|remover|altere|alterar|modifique|modificar|edite|"
    r"editar|corrija|corrigir|atualize|atualizar|insira|inserir|grave|gravar|zere|zerar|mude|mudar|troque|"
    r"trocar|cadastre|cadastrar|crie|criar)\b.*\b(dados?|registros?|viagens?|tabelas?|banco|base|numeros?|"
    r"valores?|usuarios?|funcionarios?|configurac\w*|historico|senhas?)\b"
)

RESPOSTA_MANIPULACAO = (
    "Não posso mudar minhas regras nem mostrar instruções internas. Posso ajudar com os dados da operação: "
    "viagens, passageiros, créditos, anomalias, previsões e o uso do aplicativo."
)
RESPOSTA_DADO_SENSIVEL = (
    "Não tenho acesso a senhas, chaves, cadastros de usuários nem às conversas de outras pessoas, e não posso "
    "fornecê-los."
)
RESPOSTA_ALTERACAO = (
    "Eu só consulto os dados: não altero, apago nem cadastro nada. Os relatórios do Smart Report são carregados "
    "pela equipe técnica, o acesso de funcionários é criado pela equipe responsável pelo sistema e as "
    "Configurações ficam na engrenagem ao lado do seu nome."
)


class LimiteExcedido(Exception):
    pass


@dataclass(frozen=True)
class Bloqueio:
    motivo: str
    resposta: str


class LimitadorDeTaxa:
    def __init__(self, por_minuto: int = 10, por_dia: int = 300, relogio: Callable[[], float] = time.monotonic):
        self.por_minuto = por_minuto
        self.por_dia = por_dia
        self._relogio = relogio
        self._pedidos: dict[str, deque[float]] = defaultdict(deque)
        self._trava = Lock()

    def registrar(self, chave: str) -> None:
        agora = self._relogio()
        with self._trava:
            pedidos = self._pedidos[chave]
            while pedidos and agora - pedidos[0] >= 86400:
                pedidos.popleft()
            if sum(1 for momento in pedidos if agora - momento < 60) >= self.por_minuto:
                raise LimiteExcedido("Muitas perguntas em pouco tempo. Espere um minuto e tente de novo.")
            if len(pedidos) >= self.por_dia:
                raise LimiteExcedido("Você atingiu o limite de perguntas de hoje. Tente de novo amanhã.")
            pedidos.append(agora)


limitador = LimitadorDeTaxa()


def limpar_entrada(mensagem: str) -> str:
    texto = CARACTERES_DE_CONTROLE.sub(" ", mensagem)
    texto = re.sub(r"[ \t]+", " ", texto)
    return re.sub(r"\n{3,}", "\n\n", texto).strip()[:TAMANHO_MAXIMO]


def bloqueio(mensagem: str) -> Bloqueio | None:
    texto = normalizar(mensagem)
    if any(re.search(p, texto) for p in MANIPULACAO):
        return Bloqueio("manipulacao", RESPOSTA_MANIPULACAO)
    if any(re.search(p, texto) for p in DADO_SENSIVEL):
        return Bloqueio("dado_sensivel", RESPOSTA_DADO_SENSIVEL)
    return None


def pede_alteracao(mensagem: str) -> Bloqueio | None:
    if re.search(ALTERACAO, normalizar(mensagem)):
        return Bloqueio("alteracao", RESPOSTA_ALTERACAO)
    return None


def limpar_saida(texto: str) -> str:
    texto = re.sub(r"```.*?```", "", texto, flags=re.DOTALL)
    texto = re.sub(r"(\*\*|__|`|^#{1,6}\s*)", "", texto, flags=re.MULTILINE)
    return texto.strip()[:TAMANHO_MAXIMO_DA_RESPOSTA]

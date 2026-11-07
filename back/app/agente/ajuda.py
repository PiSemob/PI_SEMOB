import re
from dataclasses import dataclass

from app.texto import normalizar

CAPACIDADES = (
    "Sou o Ferret Jr. Respondo com os dados oficiais dos relatórios da SEMOB e com os modelos de machine "
    "learning. Posso ajudar com:\n"
    "• viagens, quilometragem e cumprimento de um período;\n"
    "• comparação entre dois períodos;\n"
    "• qual linha fez mais ou menos viagens;\n"
    "• passageiros e não pagantes por dia;\n"
    "• horário de pico;\n"
    "• viagens não realizadas, não iniciadas ou não terminadas;\n"
    "• venda e utilização de créditos;\n"
    "• dias atípicos (Isolation Forest) e viagens atípicas de uma linha (DBSCAN);\n"
    "• previsão de passageiros, viagens ou km para até 14 dias;\n"
    "• onde encontrar cada coisa no aplicativo.\n"
    "Exemplo: \"Qual linha fez mais viagens em agosto?\""
)

LIMITES = (
    "Eu só consulto os dados. Não altero nem apago registros, não cadastro nem removo usuários, não mudo "
    "configurações, não tenho acesso a senhas nem às conversas de outras pessoas e não invento números: "
    "quando não há registro, eu digo que não encontrei."
)

FORA_DO_ESCOPO = (
    "Esse assunto está fora do que eu consigo responder. Trabalho só com a operação do transporte municipal "
    "de São Caetano do Sul: viagens, linhas, passageiros, créditos, anomalias, previsões e o uso do aplicativo."
)


@dataclass(frozen=True)
class Topico:
    padrao: str
    resposta: str


TOPICOS = (
    Topico(
        r"export|baix|pdf|excel|planilha|csv|relatorio",
        "Os relatórios ficam em Dados e relatórios › Relatórios. Escolha o modelo (Executivo, Operacional, "
        "Financeiro ou Prestação de Contas) e o período no alto da tela, clique em \"Gerar relatório\" e depois em "
        "PDF, Excel ou CSV para baixar. O botão \"Exportar\" do cabeçalho leva direto para lá.",
    ),
    Topico(
        r"senha",
        "Na tela de login, clique em \"Esqueci minha senha\" e informe seu e-mail institucional. Você recebe um "
        "link, válido por 60 minutos, para criar uma senha nova com pelo menos 8 caracteres.",
    ),
    Topico(
        r"cadastr|usuario|funcionario|acesso|conta|permiss",
        "Funcionários novos são cadastrados por um administrador na tela Usuários, no menu lateral. Ele informa "
        "o nome e o e-mail, e a pessoa recebe um convite por e-mail para criar a própria senha. Eu não crio, "
        "não altero e não removo usuários.",
    ),
    Topico(
        r"configur|engrenagem|alerta|notifica|sino|automatic",
        "As Configurações abrem pela engrenagem ao lado do seu nome, na barra lateral. Lá ficam o nome da "
        "organização, os alertas de anomalia que aparecem no sino do cabeçalho e o envio diário do Relatório "
        "Executivo por e-mail.",
    ),
    Topico(
        r"atualiz|carreg|novos dados|dados novos",
        "Os dados vêm dos relatórios do Smart Report, carregados pela equipe técnica. O cabeçalho mostra até "
        "que dia há dados.",
    ),
    Topico(
        r"previs",
        "As previsões ficam em Operação › Demanda (passageiros) e Operação › Quilometragem (viagens e km, do "
        "sistema ou da linha escolhida). Você também pode me pedir, por exemplo: \"previsão de viagens da linha "
        "04 para a próxima semana\".",
    ),
    Topico(
        r"anomal|atipic|fora do padrao|estranh",
        "Os dias e as viagens atípicos ficam em Operação › Operação da Frota. Escolha uma linha para ver as "
        "viagens atípicas dela. O sino do cabeçalho também avisa os casos dos últimos 7 dias.",
    ),
    Topico(
        r"credit|receita|venda|financ|saldo",
        "Vendas, utilização e saldo de créditos ficam em Financeiro › Receita e Créditos em Circulação.",
    ),
    Topico(
        r"passageir|demanda",
        "Os passageiros ficam em Operação › Demanda, com a previsão dos próximos 7 dias.",
    ),
    Topico(
        r"periodo|filtro|data",
        "Use o filtro de período no alto das telas: último dia, últimos 7, 15 ou 30 dias, último mês ou um "
        "intervalo personalizado. Os períodos contam a partir do último dia com dados.",
    ),
    Topico(
        r"documento|arquivo|integra|origem",
        "Os relatórios originais do Smart Report e a situação de cada base ficam em Dados e relatórios › "
        "Central de Documentos e Integrações de Dados.",
    ),
)

COMO_USAR = (
    (r"^como (eu )?(faco|exporto|baixo|gero|troco|recupero|mudo|altero|crio|cadastro|adiciono|configuro|ligo|"
     r"desligo|vejo|acesso|encontro|uso|filtro|atualizo|carrego)\b"),
    r"\bonde (fica|ficam|vejo|encontro|esta|estao|acho)\b",
    r"\b(em )?(que|qual) (tela|aba|menu)\b",
    r"^(tem como|da para|da pra|consigo|posso|e possivel)\b",
    r"\bo que (eu )?(faco|preciso fazer) para\b",
)


def responder(mensagem: str) -> str | None:
    texto = normalizar(mensagem)
    if re.search(r"o que (voce|vc) nao (faz|pode|consegue)", texto):
        return LIMITES
    if re.search(r"^(oi|ola|bom dia|boa tarde|boa noite|ajuda|help)\b|o que (voce|vc) (faz|sabe|pode)|"
                 r"como (voce|vc) funciona|quem e (voce|vc)", texto):
        return CAPACIDADES
    if not any(re.search(p, texto) for p in COMO_USAR):
        return None
    return next((t.resposta for t in TOPICOS if re.search(t.padrao, texto)), None)


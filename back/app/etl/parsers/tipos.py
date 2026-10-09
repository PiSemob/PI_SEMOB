"""Catálogo dos relatórios do Smart Report.

Diz, para cada título de relatório, qual é o tipo e quais colunas esperar.
Não abre arquivo nenhum: só guarda conhecimento.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class TipoRelatorio:
    chave: str  
    titulo: str  
    colunas: tuple[str, ...]  



_COLUNAS_EXCECAO = (
    "Data", "Linha", "Atendimento", "Prefixo", "Atividade", "Motorista", "Sentido",
    "Tabela", "statusSaida", "statusChegada", "inicioProgramado", "inicioRealizado",
    "fimProgramado", "fimRealizado", "kmProd",
)

TIPOS: tuple[TipoRelatorio, ...] = (
    TipoRelatorio(
        chave="resumo_geral",
        titulo="Resumo Geral",
        colunas=("Data", "diaSem", "nrVeiculos", "nrMaxVeicFx", "nrViagensProgr",
                 "nrViagensRealiz", "Dif Viagens", "kmProd", "kmImprod", "kmTotal"),
    ),
    TipoRelatorio(
        chave="fcv",
        titulo="Fator de Cumprimento de Viagem",
        colunas=("Data", "manha_p", "manha_r", "tarde_p", "tarde_r", "noite_p", "noite_r",
                 "programadas", "realizadas"),
    ),
    TipoRelatorio(
        chave="partidas_faixa_horaria",
        titulo="Partidas por Faixa Horária",
        colunas=("Data", "Linha", "Fx_Hor", "Nr_Veiculos", "Nr_Viagens", "Partidas"),
    ),
    TipoRelatorio(
        chave="resumo_faixa_horaria",
        titulo="Resumo por Faixa Horária",
        colunas=("Data", "Fx_Hor", "Nr_Veiculos", "Nr_Viagens"),
    ),
    TipoRelatorio(
        chave="resumo_linha",
        titulo="Resumo por Linha",
        colunas=("Data", "Linha", "kmTotal", "nrViagens"),
    ),
    TipoRelatorio(
        chave="viagens",
        titulo="Viagens",
        colunas=("Data", "Linha", "Prefixo", "Atividade", "Sentido", "Fx_Hor",
                 "inicioRealizado", "fimRealizado", "kmProd", "kmImprod", "kmTotal"),
    ),
    TipoRelatorio("viagens_nao_iniciadas", "Viagens não Iniciadas", _COLUNAS_EXCECAO),
    TipoRelatorio("viagens_nao_realizadas", "Viagens não Realizadas", _COLUNAS_EXCECAO),
    TipoRelatorio("viagens_nao_terminadas", "Viagens não Terminadas", _COLUNAS_EXCECAO),
    TipoRelatorio(
        chave="passageiros",
        titulo="Passageiros do Sistema",
        colunas=("Mês", "Dia", "Catraca", "Antecipados", "Não Pagantes", "Total Passageiros"),
    ),
    TipoRelatorio(
        chave="saldos",
        titulo="Saldo de créditos do sistema",
        colunas=("Mês", "Dia", "Série", "Créditos transferidos para cartões", "Saldo Final"),
    ),
    TipoRelatorio(
        chave="vendas",
        titulo="Venda x Utilização",
        colunas=("Mês", "Dia", "Total Vendas", "Total Utilização", "Crédito Circulante"),
    ),
)


def identificar(titulo: str) -> TipoRelatorio | None:
    """Devolve o tipo do relatório a partir do título do HTML, ou None se for desconhecido.

    O título vem com prefixo ("Mensal - Viagens", "São Caetano do Sul - Passageiros
    do Sistema"). A comparação é do texto inteiro depois do prefixo, porque "Viagens"
    também aparece dentro de "Viagens não Realizadas".
    """
    nome = titulo.split(" - ", 1)[-1].strip()
    for tipo in TIPOS:
        if tipo.titulo == nome:
            return tipo
    return None
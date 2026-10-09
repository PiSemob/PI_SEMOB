#le o banco, padroniza, normaliza, remode duplicatas e etc 


"""Limpeza: transforma o dado bruto (texto) em tabelas prontas para o PostgreSQL.

Para cada tabela, nesta ordem:
  1. converte texto em número, data e horário;
  2. descarta as linhas de total dos relatórios (elas não têm data válida);
  3. quando o mesmo registro vem de dois arquivos, fica o do arquivo gerado por último;
  4. sinaliza o que parece errado, sem apagar.
"""

from datetime import datetime
from functools import lru_cache
from typing import Callable, Iterable

import pandas as pd
from sqlalchemy import Table
from sqlalchemy.dialects import postgresql, sqlite

from app.etl.parsers.tipos import TipoRelatorio

_MESES_ABREVIADOS = {
    "Jan": 1, "Fev": 2, "Mar": 3, "Abr": 4, "Mai": 5, "Jun": 6,
    "Jul": 7, "Ago": 8, "Set": 9, "Out": 10, "Nov": 11, "Dez": 12,
}


DURACAO_MINIMA = 5
DURACAO_MAXIMA = 120

_SITUACOES = {
    "viagens_nao_iniciadas": "nao_iniciada",
    "viagens_nao_realizadas": "nao_realizada",
    "viagens_nao_terminadas": "nao_terminada",
}

_LOTE = 1000 


# ---------------------------------------------------------------- conversores


def numero(serie: pd.Series) -> pd.Series:
    """Texto no formato brasileiro para número: '20.434.667,35' vira 20434667.35."""
    limpo = serie.str.strip().str.replace(".", "", regex=False).str.replace(",", ".", regex=False)
    return pd.to_numeric(limpo, errors="coerce")


def inteiro(serie: pd.Series) -> pd.Series:
    """Como `numero`, mas para contagens: '5.168' vira 5168."""
    return numero(serie).round().astype("Int64")


def data_br(serie: pd.Series) -> pd.Series:
    """'01/08/2026' vira data. O que não for data (linha de total) vira vazio."""
    return pd.to_datetime(serie, format="%d/%m/%Y", errors="coerce")


def data_mes_dia(mes: pd.Series, dia: pd.Series) -> pd.Series:
    """Colunas separadas '2026-08' e '01' viram uma data só."""
    return pd.to_datetime(mes + "-" + dia, format="%Y-%m-%d", errors="coerce")


def momento(serie: pd.Series) -> pd.Series:
    """'2026-08-01 04:34:22' vira data e hora. Texto vazio vira vazio."""
    return pd.to_datetime(serie, format="%Y-%m-%d %H:%M:%S", errors="coerce")


def faixa_horaria(serie: pd.Series) -> pd.Series:
    """'4' e '4hs' viram o número 4."""
    return inteiro(serie.str.replace("hs", "", regex=False))


def texto_ou_nulo(serie: pd.Series) -> pd.Series:
    """Texto vazio vira nulo, para o banco não guardar ''."""
    return serie.where(serie != "", None)


@lru_cache(maxsize=None)
def data_de_geracao(texto: str, mes_referencia: str) -> datetime:
    """Converte a data de geração do arquivo, que vem em dois formatos.

    '04/09/2026 08:00' traz o ano. '04-Set 08:01' não traz: o ano vem do mês de
    referência da pasta. Se o arquivo foi gerado em um mês anterior ao de
    referência (dezembro gerado em janeiro), o ano é o seguinte.
    """
    if "/" in texto:
        return datetime.strptime(texto, "%d/%m/%Y %H:%M")
    dia_mes, hora = texto.split()
    dia, abreviado = dia_mes.split("-")
    ano, mes_ref = (int(parte) for parte in mes_referencia.split("-"))
    mes = _MESES_ABREVIADOS[abreviado]
    if mes < mes_ref:
        ano += 1
    horas, minutos = (int(parte) for parte in hora.split(":"))
    return datetime(ano, mes, int(dia), horas, minutos)


# ------------------------------------------------------------ do bruto à tabela


def tabela_bruta(documentos: Iterable[dict], tipo: TipoRelatorio) -> pd.DataFrame:
    """Junta os documentos de um tipo (como saem do MongoDB) em uma tabela só.

    As colunas do relatório continuam como texto. Entram duas colunas de origem:
    `arquivo_origem` e `gerado_em` (já convertida em data e hora).
    """
    linhas = [
        {
            **documento["dados"],
            "arquivo_origem": documento["arquivo_origem"],
            "gerado_em": data_de_geracao(documento["gerado_em"], documento["mes_referencia"]),
        }
        for documento in documentos
    ]
    return pd.DataFrame(linhas, columns=[*tipo.colunas, "arquivo_origem", "gerado_em"])


def _finalizar(df: pd.DataFrame, chave: list[str]) -> pd.DataFrame:
    """Passos comuns a todas as tabelas, depois da conversão."""
    df = df.dropna(subset=chave)
    df = df.sort_values("gerado_em").drop_duplicates(subset=chave, keep="last")
    df = df.reset_index(drop=True)
    df["data"] = df["data"].dt.date
    if "suspeito" not in df:
        df["suspeito"] = False
        df["motivo_suspeita"] = None
    return df


def _origem(bruto: pd.DataFrame) -> dict:
    return {"arquivo_origem": bruto["arquivo_origem"], "gerado_em": bruto["gerado_em"]}


# ----------------------------------------------------------- uma função por tabela


def limpar_viagens(bruto: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Devolve duas tabelas: as viagens realizadas e a quilometragem improdutiva.

    O relatório Viagens mistura as duas coisas. As linhas "Improdutivas" não têm
    linha, sentido nem horário: são o km improdutivo de um veículo em um dia.
    """
    df = pd.DataFrame(
        {
            "data": data_br(bruto["Data"]),
            "linha": bruto["Linha"],
            "prefixo": bruto["Prefixo"],
            "atividade": bruto["Atividade"],
            "inicio_realizado": momento(bruto["inicioRealizado"]),
            "fim_realizado": momento(bruto["fimRealizado"]),
            "sentido": texto_ou_nulo(bruto["Sentido"]),
            "fx_hor": faixa_horaria(bruto["Fx_Hor"]),
            "km_prod": numero(bruto["kmProd"]),
            "km_improd": numero(bruto["kmImprod"]),
            "km_total": numero(bruto["kmTotal"]),
            **_origem(bruto),
        }
    )
    eh_improdutiva = df["atividade"] == "Improdutivas"

    viagens = df[~eh_improdutiva].drop(columns="atividade")
    duracao = (viagens["fim_realizado"] - viagens["inicio_realizado"]).dt.total_seconds() / 60
    viagens["duracao_min"] = duracao.round(1)

   
    viagens["motivo_suspeita"] = None
    regras = [
        ((duracao < DURACAO_MINIMA) | (duracao > DURACAO_MAXIMA), "duração fora do comum"),
        (viagens["km_total"] <= 0, "quilometragem zero"),
        (viagens["fim_realizado"].isna(), "sem horário de fim"),
        (viagens["fim_realizado"] <= viagens["inicio_realizado"], "fim antes do início"),
    ]
    for condicao, motivo in regras:
        viagens.loc[condicao, "motivo_suspeita"] = motivo
    viagens["suspeito"] = viagens["motivo_suspeita"].notna()

    improdutivas = df.loc[
        eh_improdutiva,
        ["data", "prefixo", "km_prod", "km_improd", "km_total", "arquivo_origem", "gerado_em"],
    ]
    return (
        _finalizar(viagens, ["data", "linha", "prefixo", "inicio_realizado"]),
        _finalizar(improdutivas, ["data", "prefixo"]),
    )


def limpar_excecoes(brutos: dict[str, pd.DataFrame]) -> pd.DataFrame:
    """Junta as três listas de viagens com problema em uma tabela, com a `situacao`."""
    partes = []
    for chave, situacao in _SITUACOES.items():
        bruto = brutos[chave]
        partes.append(
            pd.DataFrame(
                {
                    "situacao": situacao,
                    "data": data_br(bruto["Data"]),
                    "linha": bruto["Linha"],
                    "tabela": bruto["Tabela"],
                    "sentido": bruto["Sentido"],
                    "inicio_programado": momento(bruto["inicioProgramado"]),
                    "inicio_realizado": momento(bruto["inicioRealizado"]),
                    "fim_programado": momento(bruto["fimProgramado"]),
                    "fim_realizado": momento(bruto["fimRealizado"]),
                    "atendimento": texto_ou_nulo(bruto["Atendimento"]),
                    "prefixo": texto_ou_nulo(bruto["Prefixo"]),
                    "atividade": texto_ou_nulo(bruto["Atividade"]),
                    "motorista": texto_ou_nulo(bruto["Motorista"]),
                    "status_saida": texto_ou_nulo(bruto["statusSaida"]),
                    "status_chegada": texto_ou_nulo(bruto["statusChegada"]),
                    "km_prod": numero(bruto["kmProd"]),
                    **_origem(bruto),
                }
            )
        )
    df = pd.concat(partes, ignore_index=True)
    return _finalizar(df, ["situacao", "data", "linha", "tabela", "sentido", "inicio_programado"])


def limpar_resumo_geral(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_br(bruto["Data"]),
            "dia_sem": bruto["diaSem"],
            "nr_veiculos": inteiro(bruto["nrVeiculos"]),
            "nr_max_veic_fx": inteiro(bruto["nrMaxVeicFx"]),
            "nr_viagens_progr": inteiro(bruto["nrViagensProgr"]),
            "nr_viagens_realiz": inteiro(bruto["nrViagensRealiz"]),
            "dif_viagens": inteiro(bruto["Dif Viagens"]),
            "km_prod": numero(bruto["kmProd"]),
            "km_improd": numero(bruto["kmImprod"]),
            "km_total": numero(bruto["kmTotal"]),
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data"])


def limpar_resumo_linha(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_br(bruto["Data"]),
            "linha": bruto["Linha"],
            "km_total": numero(bruto["kmTotal"]),
            "nr_viagens": inteiro(bruto["nrViagens"]),
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data", "linha"])


def limpar_partidas_faixa_horaria(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_br(bruto["Data"]),
            "linha": bruto["Linha"],
            "fx_hor": faixa_horaria(bruto["Fx_Hor"]),
            "nr_veiculos": inteiro(bruto["Nr_Veiculos"]),
            "nr_viagens": inteiro(bruto["Nr_Viagens"]),
            "partidas": bruto["Partidas"],
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data", "linha", "fx_hor"])


def limpar_resumo_faixa_horaria(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_br(bruto["Data"]),
            "fx_hor": faixa_horaria(bruto["Fx_Hor"]),
            "nr_veiculos": inteiro(bruto["Nr_Veiculos"]),
            "nr_viagens": inteiro(bruto["Nr_Viagens"]),
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data", "fx_hor"])


def limpar_fcv(bruto: pd.DataFrame) -> pd.DataFrame:
    contagens = ["manha_p", "manha_r", "tarde_p", "tarde_r", "noite_p", "noite_r",
                 "programadas", "realizadas"]
    df = pd.DataFrame(
        {
            "data": data_br(bruto["Data"]),
            **{coluna: inteiro(bruto[coluna]) for coluna in contagens},
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data"])


def limpar_passageiros(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_mes_dia(bruto["Mês"], bruto["Dia"]),
            "catraca": inteiro(bruto["Catraca"]),
            "antecipados": inteiro(bruto["Antecipados"]),
            "nao_pagantes": inteiro(bruto["Não Pagantes"]),
            "total": inteiro(bruto["Total Passageiros"]),
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data"])


def limpar_saldos(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_mes_dia(bruto["Mês"], bruto["Dia"]),
            "serie": bruto["Série"],
            "creditos_transferidos": numero(bruto["Créditos transferidos para cartões"]),
            "saldo_final": numero(bruto["Saldo Final"]),
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data", "serie"])


def limpar_vendas(bruto: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame(
        {
            "data": data_mes_dia(bruto["Mês"], bruto["Dia"]),
            "total_vendas": numero(bruto["Total Vendas"]),
            "total_utilizacao": numero(bruto["Total Utilização"]),
            "credito_circulante": numero(bruto["Crédito Circulante"]),
            **_origem(bruto),
        }
    )
    return _finalizar(df, ["data"])


def limpar_tudo(ler: Callable[[str], pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """Limpa todos os relatórios e devolve um dicionário {nome da tabela: dados limpos}.

    `ler(chave)` devolve a tabela bruta de um tipo de relatório (ver `tabela_bruta`).
    """
    viagens, improdutivas = limpar_viagens(ler("viagens"))
    return {
        "viagens": viagens,
        "viagens_improdutivas": improdutivas,
        "viagens_excecao": limpar_excecoes({chave: ler(chave) for chave in _SITUACOES}),
        "resumo_geral": limpar_resumo_geral(ler("resumo_geral")),
        "resumo_linha": limpar_resumo_linha(ler("resumo_linha")),
        "partidas_faixa_horaria": limpar_partidas_faixa_horaria(ler("partidas_faixa_horaria")),
        "resumo_faixa_horaria": limpar_resumo_faixa_horaria(ler("resumo_faixa_horaria")),
        "fcv": limpar_fcv(ler("fcv")),
        "passageiros": limpar_passageiros(ler("passageiros")),
        "saldos": limpar_saldos(ler("saldos")),
        "vendas": limpar_vendas(ler("vendas")),
    }


# ------------------------------------------------------------------ gravação


def gravar(conexao, tabela: Table, df: pd.DataFrame) -> int:
    """Grava os dados limpos com "inserir ou atualizar" pela chave primária.

    Se o registro já existe, os outros campos são atualizados. Por isso rodar a
    carga duas vezes dá o mesmo resultado que rodar uma.
    """
    dados = df[[coluna.name for coluna in tabela.columns]]
   
    registros = dados.astype(object).where(dados.notna(), None).to_dict("records")
    if not registros:
        return 0

   
    inserir = sqlite.insert if conexao.dialect.name == "sqlite" else postgresql.insert
    comando = inserir(tabela)
    chave = [coluna.name for coluna in tabela.primary_key.columns]
    comando = comando.on_conflict_do_update(
        index_elements=chave,
        set_={
            coluna.name: comando.excluded[coluna.name]
            for coluna in tabela.columns
            if not coluna.primary_key
        },
    )
    for inicio in range(0, len(registros), _LOTE):
        conexao.execute(comando, registros[inicio : inicio + _LOTE])
    return len(registros)
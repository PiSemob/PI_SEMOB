# definição das tabelas do postgre


"""Definição das tabelas do PostgreSQL (a camada limpa).

A chave primária de cada tabela é o que identifica um registro. É ela que impede
o mesmo dia de entrar duas vezes quando aparece no relatório Mensal e no Quinzenal.
"""

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Float,
    Integer,
    MetaData,
    Numeric,
    SmallInteger,
    String,
    Table,
    Text,
)

metadata = MetaData()

KM = Numeric(10, 2)
DINHEIRO = Numeric(16, 2)


def _controle() -> list[Column]:
    """Colunas presentes em todas as tabelas: sinalização e origem do dado."""
    return [
        Column("suspeito", Boolean, nullable=False, default=False),
        Column("motivo_suspeita", Text),
        Column("arquivo_origem", Text, nullable=False),
        Column("gerado_em", DateTime, nullable=False),
    ]



viagens = Table(
    "viagens",
    metadata,
    Column("data", Date, primary_key=True),  
    Column("linha", String(4), primary_key=True),
    Column("prefixo", String(10), primary_key=True),  
    Column("inicio_realizado", DateTime, primary_key=True),
    Column("fim_realizado", DateTime),
    Column("sentido", String(1)), 
    Column("fx_hor", SmallInteger),
    Column("duracao_min", Float),
    Column("km_prod", KM),
    Column("km_improd", KM),
    Column("km_total", KM),
    *_controle(),
)


viagens_improdutivas = Table(
    "viagens_improdutivas",
    metadata,
    Column("data", Date, primary_key=True),
    Column("prefixo", String(10), primary_key=True),
    Column("km_prod", KM),
    Column("km_improd", KM),
    Column("km_total", KM),
    *_controle(),
)


viagens_excecao = Table(
    "viagens_excecao",
    metadata,
    Column("situacao", String(15), primary_key=True),  
    Column("data", Date, primary_key=True),
    Column("linha", String(4), primary_key=True),
    Column("tabela", String(10), primary_key=True),  
    Column("sentido", String(1), primary_key=True),
    Column("inicio_programado", DateTime, primary_key=True),
    Column("inicio_realizado", DateTime),
    Column("fim_programado", DateTime),
    Column("fim_realizado", DateTime),
    Column("atendimento", Text),
    Column("prefixo", String(10)),  
    Column("atividade", String(30)),
    Column("motorista", String(10)), 
    Column("status_saida", String(5)),
    Column("status_chegada", String(5)),
    Column("km_prod", KM),
    *_controle(),
)

resumo_geral = Table(
    "resumo_geral",
    metadata,
    Column("data", Date, primary_key=True),
    Column("dia_sem", String(3)),
    Column("nr_veiculos", Integer),
    Column("nr_max_veic_fx", Integer),
    Column("nr_viagens_progr", Integer),
    Column("nr_viagens_realiz", Integer),
    Column("dif_viagens", Integer),
    Column("km_prod", KM),
    Column("km_improd", KM),
    Column("km_total", KM),
    *_controle(),
)

resumo_linha = Table(
    "resumo_linha",
    metadata,
    Column("data", Date, primary_key=True),
    Column("linha", String(4), primary_key=True),
    Column("km_total", KM),
    Column("nr_viagens", Integer),
    *_controle(),
)

partidas_faixa_horaria = Table(
    "partidas_faixa_horaria",
    metadata,
    Column("data", Date, primary_key=True),
    Column("linha", String(4), primary_key=True),
    Column("fx_hor", SmallInteger, primary_key=True),
    Column("nr_veiculos", Integer),
    Column("nr_viagens", Integer),
    Column("partidas", Text),  
    *_controle(),
)

resumo_faixa_horaria = Table(
    "resumo_faixa_horaria",
    metadata,
    Column("data", Date, primary_key=True),
    Column("fx_hor", SmallInteger, primary_key=True),
    Column("nr_veiculos", Integer),
    Column("nr_viagens", Integer),
    *_controle(),
)

fcv = Table(
    "fcv",
    metadata,
    Column("data", Date, primary_key=True),
    Column("manha_p", Integer),  
    Column("manha_r", Integer),
    Column("tarde_p", Integer),
    Column("tarde_r", Integer),
    Column("noite_p", Integer),
    Column("noite_r", Integer),
    Column("programadas", Integer),
    Column("realizadas", Integer),
    *_controle(),
)

passageiros = Table(
    "passageiros",
    metadata,
    Column("data", Date, primary_key=True),
    Column("catraca", Integer),
    Column("antecipados", Integer),
    Column("nao_pagantes", Integer),
    Column("total", Integer),
    *_controle(),
)

saldos = Table(
    "saldos",
    metadata,
    Column("data", Date, primary_key=True),
    Column("serie", String(5), primary_key=True),
    Column("creditos_transferidos", DINHEIRO),
    Column("saldo_final", DINHEIRO),
    *_controle(),
)

vendas = Table(
    "vendas",
    metadata,
    Column("data", Date, primary_key=True),
    Column("total_vendas", DINHEIRO),
    Column("total_utilizacao", DINHEIRO),
    Column("credito_circulante", DINHEIRO),
    *_controle(),
)
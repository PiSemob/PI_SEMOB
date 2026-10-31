from datetime import date, datetime

import numpy as np
import pandas as pd
import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, select

from app.api.dependencias import linhas_da_consulta, tabela_para_json, validar_periodo
from app.db import tabelas


def test_periodo_de_um_dia_e_aceito():
    validar_periodo(date(2026, 8, 1), date(2026, 8, 1))


def test_inicio_depois_do_fim_e_recusado():
    with pytest.raises(HTTPException) as erro:
        validar_periodo(date(2026, 8, 3), date(2026, 8, 1))
    assert erro.value.status_code == 400


@pytest.mark.filterwarnings("ignore::sqlalchemy.exc.SAWarning")
def test_decimal_do_banco_vira_numero():
    engine = create_engine("sqlite://")
    tabelas.metadata.create_all(engine, tables=[tabelas.resumo_linha])
    with engine.begin() as conexao:
        conexao.execute(
            tabelas.resumo_linha.insert(),
            {"data": date(2026, 8, 1), "linha": "01", "km_total": 700, "nr_viagens": 60,
             "arquivo_origem": "teste.html", "gerado_em": datetime(2026, 9, 4, 8, 0)},
        )
        t = tabelas.resumo_linha
        (linha,) = linhas_da_consulta(conexao, select(t.c.linha, t.c.km_total, t.c.nr_viagens))

    assert linha == {"linha": "01", "km_total": 700.0, "nr_viagens": 60}
    assert isinstance(linha["km_total"], float)


def test_tabela_vira_lista_pronta_para_json():
    tabela = pd.DataFrame(
        {
            "data": pd.to_datetime(["2026-08-01", "2026-08-02"]),
            "inicio_realizado": pd.to_datetime(["2026-08-01 04:34:22", "2026-08-02 05:00:00"]),
            "duracao_min": [23.6, np.nan],
        }
    )
    assert tabela_para_json(tabela) == [
        {"data": "2026-08-01", "inicio_realizado": "2026-08-01T04:34:22", "duracao_min": 23.6},
        {"data": "2026-08-02", "inicio_realizado": "2026-08-02T05:00:00", "duracao_min": None},
    ]

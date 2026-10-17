"""Regressão: mudança em parser ou limpeza não pode alterar os meses que já estavam certos.

Compara a leitura atual com `linha_de_base.json` (ver linha_de_base.py). Um arquivo
novo em dados/brutos não quebra nada; um arquivo ou mês que sumiu ou mudou, quebra.
"""

import pytest

from tests.regressao.linha_de_base import BRUTOS, carregar, medir_arquivo, medir_tabela

BASE = carregar()

PARES_TABELA_MES = [
    (tabela, mes) for tabela, meses in BASE["tabelas"].items() for mes in meses
]
IDS_TABELA_MES = [f"{tabela}-{mes}" for tabela, mes in PARES_TABELA_MES]


@pytest.mark.parametrize("arquivo", BASE["arquivos"])
def test_arquivo_continua_sendo_lido_igual(arquivo):
    caminho = BRUTOS / arquivo
    assert caminho.is_file(), f"arquivo da linha de base sumiu: {arquivo}"
    assert medir_arquivo(caminho) == BASE["arquivos"][arquivo]


@pytest.fixture(scope="module")
def medidas_atuais(limpas):
    return {nome: medir_tabela(df) for nome, df in limpas.items()}


@pytest.mark.parametrize(("tabela", "mes"), PARES_TABELA_MES, ids=IDS_TABELA_MES)
def test_mes_continua_com_os_mesmos_numeros(medidas_atuais, tabela, mes):
    atual = medidas_atuais[tabela].get(mes)
    assert atual is not None, f"{tabela}: o mês {mes} sumiu"
    esperado = BASE["tabelas"][tabela][mes]
    assert atual["registros"] == esperado["registros"]
    assert atual["suspeitos"] == esperado["suspeitos"]
    assert atual["somas"] == pytest.approx(esperado["somas"], abs=0.01)


def test_nenhuma_tabela_sumiu(medidas_atuais):
    assert set(BASE["tabelas"]) <= set(medidas_atuais)

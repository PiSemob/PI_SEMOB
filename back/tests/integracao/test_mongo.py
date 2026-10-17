"""Integração com o container do MongoDB (camada bruta), usando relatórios reais."""

import pytest

from app.etl.carga_bruta import gravar_bruto
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import identificar
from tests.apoio import BANCO_INTEGRACAO, BRUTOS, recriar_mongo

LINHAS_MENSAL = BRUTOS / "Agosto_2026" / "Mensal" / "Mensal_Linhas_202608.html"
LINHAS_QUINZENAL = BRUTOS / "Agosto_2026" / "Quinzenal" / "Quinzenal_Linhas_202608.html"


@pytest.fixture
def mongo(bancos_no_ar):
    banco = recriar_mongo(BANCO_INTEGRACAO)
    yield banco
    banco.client.drop_database(BANCO_INTEGRACAO)


def gravar(banco, caminho):
    (relatorio,) = ler_arquivo(caminho)
    return relatorio, gravar_bruto(banco, relatorio, identificar(relatorio.titulo))


def test_relatorio_real_fica_gravado_com_os_metadados(mongo):
    relatorio, quantidade = gravar(mongo, LINHAS_MENSAL)

    assert quantidade == len(relatorio.tabela)
    assert mongo["resumo_linha"].count_documents({}) == len(relatorio.tabela)
    documento = mongo["resumo_linha"].find_one(
        {"dados.Data": "01/08/2026", "dados.Linha": "01"}, {"_id": 0}
    )
    assert documento == {
        "tipo": "resumo_linha",
        "periodo": "mensal",
        "mes_referencia": "2026-08",
        "arquivo_origem": "Agosto_2026/Mensal/Mensal_Linhas_202608.html",
        "gerado_em": "04/09/2026 08:00",
        "dados": {"Data": "01/08/2026", "Linha": "01", "kmTotal": "650", "nrViagens": "98"},
    }


def test_gravar_o_mesmo_arquivo_duas_vezes_nao_duplica(mongo):
    _, primeira = gravar(mongo, LINHAS_MENSAL)
    _, segunda = gravar(mongo, LINHAS_MENSAL)

    assert primeira == segunda
    assert mongo["resumo_linha"].count_documents({}) == primeira


def test_regravar_um_arquivo_nao_apaga_o_outro_da_mesma_colecao(mongo):
    _, mensal = gravar(mongo, LINHAS_MENSAL)
    relatorio_quinzenal, quinzenal = gravar(mongo, LINHAS_QUINZENAL)
    gravar(mongo, LINHAS_MENSAL)

    colecao = mongo["resumo_linha"]
    assert colecao.count_documents({}) == mensal + quinzenal
    assert colecao.count_documents({"arquivo_origem": relatorio_quinzenal.arquivo}) == quinzenal

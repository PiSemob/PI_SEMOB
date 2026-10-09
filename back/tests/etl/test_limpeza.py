from collections import defaultdict
from datetime import date, datetime
from pathlib import Path

import pandas as pd
import pytest
from sqlalchemy import create_engine, func, select

from app.db.tabelas import metadata
from app.etl.carga_bruta import montar_documentos
from app.etl.limpeza import (
    data_de_geracao,
    faixa_horaria,
    gravar,
    inteiro,
    limpar_tudo,
    numero,
    tabela_bruta,
)
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import TIPOS, identificar

BRUTOS = Path(__file__).resolve().parents[3] / "dados" / "brutos"


@pytest.fixture(scope="module")
def limpas() -> dict[str, pd.DataFrame]:
    """Lê os 44 arquivos e limpa tudo, uma vez só para todos os testes deste arquivo."""
    documentos = defaultdict(list)
    for caminho in sorted(BRUTOS.rglob("*.html")):
        for relatorio in ler_arquivo(caminho):
            tipo = identificar(relatorio.titulo)
            documentos[tipo.chave].extend(montar_documentos(relatorio, tipo))
    tipos = {tipo.chave: tipo for tipo in TIPOS}
    return limpar_tudo(lambda chave: tabela_bruta(documentos[chave], tipos[chave]))


def por_mes(df: pd.DataFrame) -> pd.Series:
    return pd.to_datetime(df["data"]).dt.month


def test_numero_no_formato_brasileiro():
    resultado = numero(pd.Series(["6,5", "20.434.667,35", "-3.380,00", "650", ""]))
    assert resultado.iloc[:4].tolist() == [6.5, 20434667.35, -3380.0, 650.0]
    assert pd.isna(resultado.iloc[4])


def test_inteiro_trata_o_ponto_como_milhar():
    assert inteiro(pd.Series(["5.168", "676", "1.050.248"])).tolist() == [5168, 676, 1050248]


def test_faixa_horaria_aceita_os_dois_formatos():
    assert faixa_horaria(pd.Series(["4", "4hs", "23hs"])).tolist() == [4, 4, 23]


def test_data_de_geracao_nos_dois_formatos():
    assert data_de_geracao("04/09/2026 08:00", "2026-08") == datetime(2026, 9, 4, 8, 0)
    assert data_de_geracao("04-Set 08:01", "2026-08") == datetime(2026, 9, 4, 8, 1)
  
    assert data_de_geracao("04-Jan 08:01", "2026-12") == datetime(2027, 1, 4, 8, 1)


def test_viagens_por_mes_sem_dobrar_agosto(limpas):

    contagem = por_mes(limpas["viagens"]).value_counts().to_dict()
    assert contagem == {7: 36330, 8: 34994, 9: 15489}


def test_viagens_batem_com_o_resumo_geral(limpas):
    viagens, improdutivas, resumo = (
        limpas["viagens"], limpas["viagens_improdutivas"], limpas["resumo_geral"],
    )
    for mes in (7, 8, 9):
        do_mes = resumo[por_mes(resumo) == mes]
        assert len(viagens[por_mes(viagens) == mes]) == do_mes["nr_viagens_realiz"].sum()
        km = (
            viagens[por_mes(viagens) == mes]["km_total"].sum()
            + improdutivas[por_mes(improdutivas) == mes]["km_total"].sum()
        )
        assert km == pytest.approx(do_mes["km_total"].sum(), abs=0.5)


def test_linha_continua_texto(limpas):
    assert "01" in set(limpas["viagens"]["linha"])


def test_linhas_de_total_nao_entram(limpas):
    resumo = limpas["resumo_geral"]
    assert len(resumo) == 31 + 31 + 14 
    assert resumo["data"].notna().all()


def test_passageiros_cobrem_de_15_de_julho_a_14_de_setembro(limpas):
    passageiros = limpas["passageiros"]
    assert passageiros["data"].min() == date(2026, 7, 15)
    assert passageiros["data"].max() == date(2026, 9, 14)
    assert len(passageiros) == 62
    assert passageiros[por_mes(passageiros) == 8]["total"].sum() == 1050248


def test_suspeitos_sao_sinalizados_e_continuam_na_tabela(limpas):
    suspeitas = limpas["viagens"][limpas["viagens"]["suspeito"]]
    assert len(suspeitas) == 4
    assert set(suspeitas["motivo_suspeita"]) == {"duração fora do comum"}


@pytest.mark.filterwarnings("ignore::sqlalchemy.exc.SAWarning")
def test_gravar_duas_vezes_nao_duplica(limpas):
    engine = create_engine("sqlite://")
    metadata.create_all(engine)
    for _ in range(2):
        with engine.begin() as conexao:
            for nome, df in limpas.items():
                gravar(conexao, metadata.tables[nome], df)
    with engine.connect() as conexao:
        for nome, df in limpas.items():
            total = conexao.scalar(select(func.count()).select_from(metadata.tables[nome]))
            assert total == len(df), nome
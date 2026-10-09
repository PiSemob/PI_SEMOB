import numpy as np
import pandas as pd
import pytest

from app.ml import dados
from app.ml.fiscalizacao import isolation_forest


def linha_dia_artificial(dias: int = 60) -> pd.DataFrame:
    """Duas linhas com operação regular: cheia nos dias úteis, menor no fim de semana."""
    sorteio = np.random.default_rng(0)
    registros = []
    for linha, viagens_dia_util in (("01", 100), ("02", 60)):
        for data in pd.date_range("2026-07-01", periods=dias):
            fator = {5: 0.6, 6: 0.4}.get(data.dayofweek, 1.0)
            nr_viagens = round(viagens_dia_util * fator + sorteio.normal(0, 2))
            km_total = nr_viagens * 7.0 + sorteio.normal(0, 5)
            registros.append(
                {
                    "data": data,
                    "linha": linha,
                    "nr_viagens": nr_viagens,
                    "km_total": km_total,
                    "km_por_viagem": km_total / nr_viagens,
                    "duracao_media": 28 + sorteio.normal(0, 1),
                    "nr_veiculos": 5,
                }
            )
    tabela = pd.DataFrame(registros)
    tabela["tipo_dia"] = dados.tipo_de_dia(tabela["data"])
    return tabela


def test_dia_absurdo_fica_no_topo():
    tabela = linha_dia_artificial()
    alvo = (tabela["linha"] == "01") & (tabela["data"] == "2026-07-15")
    tabela.loc[alvo, "km_total"] *= 10
    tabela.loc[alvo, "km_por_viagem"] *= 10

    resultado = isolation_forest.pontuar(tabela)

    primeiro = resultado.iloc[0]
    assert (primeiro["linha"], primeiro["data"]) == ("01", pd.Timestamp("2026-07-15"))
    assert primeiro["atipico"]
    assert "acima do normal" in primeiro["destaque"]


def test_fim_de_semana_nao_e_anomalia_so_por_ser_menor():
    resultado = isolation_forest.pontuar(linha_dia_artificial())
    atipicos = resultado[resultado["atipico"]]
    assert len(atipicos) <= len(resultado) * 0.05
    assert (atipicos["tipo_dia"] == "util").any() or atipicos.empty


def test_linha_com_poucos_dias_fica_de_fora():
    tabela = linha_dia_artificial()
    curta = tabela[tabela["linha"] == "02"].head(10).assign(linha="11")
    resultado = isolation_forest.pontuar(pd.concat([tabela, curta], ignore_index=True))
    assert "11" not in set(resultado["linha"])


def test_sem_linha_suficiente_da_erro_claro():
    with pytest.raises(ValueError, match="pelo menos"):
        isolation_forest.pontuar(linha_dia_artificial(dias=10))


def test_agregar_usa_o_dia_de_operacao():
    viagens = pd.DataFrame(
        {
            "data": pd.to_datetime(["2026-08-01", "2026-08-01", "2026-08-01"]),
            "linha": ["01", "01", "01"],
            "prefixo": ["1502", "1502", "1648"],
            "inicio_realizado": pd.to_datetime(
                ["2026-08-01 04:34:22", "2026-08-01 04:57:02", "2026-08-02 00:20:36"]
            ),
            "duracao_min": [18.0, 16.0, 22.0],
            "km_total": [6.5, 6.5, 8.0],
        }
    )
    (registro,) = dados.agregar_linha_dia(viagens).to_dict("records")
    assert registro["nr_viagens"] == 3
    assert registro["km_total"] == 21.0
    assert registro["km_por_viagem"] == 7.0
    assert registro["nr_veiculos"] == 2
    assert registro["tipo_dia"] == "sabado"
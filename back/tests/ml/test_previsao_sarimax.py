import numpy as np
import pandas as pd
import pytest

from app.ml.planejamento import avaliacao, previsao_sarimax


def serie_artificial(dias: int = 70) -> pd.DataFrame:
    """Série com padrão semanal fixo: 100 em dia útil, 50 no sábado, 20 no domingo."""
    sorteio = np.random.default_rng(0)
    datas = pd.date_range("2026-03-02", periods=dias)
    padrao = datas.dayofweek.map(lambda dia: {5: 50.0, 6: 20.0}.get(dia, 100.0))
    return pd.DataFrame({"ds": datas, "y": padrao + sorteio.normal(0, 2, dias)})


def test_previsao_segue_o_padrao_da_semana():
    serie = serie_artificial()
    resultado = previsao_sarimax.prever_serie(serie, 7)

    assert list(resultado.columns) == ["ds", "previsto", "minimo", "maximo"]
    assert len(resultado) == 7
    esperado = resultado["ds"].dt.dayofweek.map(lambda dia: {5: 50.0, 6: 20.0}.get(dia, 100.0))
    assert resultado["previsto"].to_numpy() == pytest.approx(esperado.to_numpy(), abs=8)
    assert (resultado["minimo"] <= resultado["previsto"]).all()
    assert (resultado["previsto"] <= resultado["maximo"]).all()


def test_aprende_o_efeito_do_feriado():
    datas = pd.date_range("2026-06-29", "2026-09-06")
    padrao = datas.dayofweek.map(lambda dia: {5: 50.0, 6: 20.0}.get(dia, 100.0)).to_numpy()
    padrao = np.where(avaliacao.eh_feriado(datas), 25.0, padrao)
    serie = pd.DataFrame({"ds": datas, "y": padrao})

    resultado = previsao_sarimax.prever_serie(serie, 2)

    assert resultado.iloc[0]["previsto"] == pytest.approx(25, abs=10)
    assert resultado.iloc[1]["previsto"] == pytest.approx(100, abs=10)


def test_resposta_tem_o_formato_combinado():
    serie = serie_artificial()
    resposta = avaliacao.responder(
        "viagens", "04", "sarimax", previsao_sarimax.prever_serie(serie, 3), {"mae": 1.0, "mape": 2.0}
    )
    assert resposta["serie"] == "viagens" and resposta["linha"] == "04"
    assert resposta["modelo"] == "sarimax"
    assert len(resposta["previsao"]) == 3
    assert set(resposta["previsao"][0]) == {"data", "previsto", "minimo", "maximo"}
    assert resposta["previsao"][0]["data"] == "2026-05-11"

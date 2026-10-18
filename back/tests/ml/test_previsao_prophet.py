import numpy as np
import pandas as pd
import pytest

from app.ml.planejamento import avaliacao, previsao_prophet


def serie_artificial(dias: int = 70) -> pd.DataFrame:
    """Série com padrão semanal fixo: 100 em dia útil, 50 no sábado, 20 no domingo."""
    sorteio = np.random.default_rng(0)
    datas = pd.date_range("2026-03-02", periods=dias)
    padrao = datas.dayofweek.map(lambda dia: {5: 50.0, 6: 20.0}.get(dia, 100.0))
    return pd.DataFrame({"ds": datas, "y": padrao + sorteio.normal(0, 2, dias)})


def test_previsao_segue_o_padrao_da_semana():
    serie = serie_artificial()
    previsao = previsao_prophet.prever_serie(serie, 7)

    assert list(previsao.columns) == ["ds", "previsto", "minimo", "maximo"]
    assert len(previsao) == 7
    assert previsao["ds"].min() == serie["ds"].max() + pd.Timedelta(days=1)
    esperado = previsao["ds"].dt.dayofweek.map(lambda dia: {5: 50.0, 6: 20.0}.get(dia, 100.0))
    assert previsao["previsto"].to_numpy() == pytest.approx(esperado.to_numpy(), abs=8)
    assert (previsao["minimo"] <= previsao["previsto"]).all()
    assert (previsao["previsto"] <= previsao["maximo"]).all()


def test_validacao_mede_erro_pequeno_em_serie_regular():
    erro = avaliacao.validar(previsao_prophet.prever_serie, serie_artificial())
    assert erro["mape"] < 10


def test_serie_curta_nao_e_validada():
    with pytest.raises(ValueError, match="curta"):
        avaliacao.validar(previsao_prophet.prever_serie, serie_artificial(dias=20))


def test_feriados_nacional_estadual_e_municipal():
    datas = ["2026-09-07", "2026-07-09", "2026-07-28", "2026-09-08"]
    assert avaliacao.eh_feriado(datas).tolist() == [True, True, True, False]

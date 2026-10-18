import numpy as np
import pandas as pd

from app.ml.planejamento import previsao


def serie_artificial(dias: int = 70) -> pd.DataFrame:
    """Série com padrão semanal fixo: 100 em dia útil, 50 no sábado, 20 no domingo."""
    sorteio = np.random.default_rng(0)
    datas = pd.date_range("2026-03-02", periods=dias)
    padrao = datas.dayofweek.map(lambda dia: {5: 50.0, 6: 20.0}.get(dia, 100.0))
    return pd.DataFrame({"ds": datas, "y": padrao + sorteio.normal(0, 2, dias)})


def test_escolhe_o_modelo_de_menor_erro():
    erros = {"prophet": {"mae": 3.4, "mape": 3.2}, "sarimax": {"mae": 2.2, "mape": 2.8}}
    assert previsao.escolher(erros) == "sarimax"
    assert previsao.chave("viagens", "04") == "viagens:04"
    assert previsao.chave("passageiros", None) == "passageiros:sistema"


def test_compara_os_dois_modelos_na_mesma_serie():
    erros = previsao.comparar(serie_artificial())
    assert set(erros) == {"prophet", "sarimax"}
    assert all(erro["mape"] < 10 for erro in erros.values())

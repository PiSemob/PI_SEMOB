import numpy as np
import pandas as pd
import pytest

from app.ml.fiscalizacao import dbscan


def viagens_artificiais() -> pd.DataFrame:
    """Uma linha com 150 viagens parecidas em cada sentido.

    Como nos dados reais, a duração varia dentro de uma faixa e a quilometragem
    assume poucos valores, porque o percurso é fixo.
    """
    sorteio = np.random.default_rng(0)
    partes = []
    for sentido, duracao, km in (("I", 28, 7.0), ("V", 32, 8.5)):
        partes.append(
            pd.DataFrame(
                {
                    "linha": "01",
                    "sentido": sentido,
                    "duracao_min": sorteio.uniform(duracao - 4, duracao + 4, 150),
                    "km_total": sorteio.choice([km, km + 0.1], 150),
                }
            )
        )
    return pd.concat(partes, ignore_index=True)


def test_so_a_viagem_isolada_vira_ruido():
    viagens = viagens_artificiais()
    isolada = pd.DataFrame(
        {"linha": ["01"], "sentido": ["I"], "duracao_min": [95.0], "km_total": [19.0]}
    )
    marcadas = dbscan.marcar_ruido(pd.concat([viagens, isolada], ignore_index=True))

    ruido = marcadas[marcadas["ruido"]]
    assert len(ruido) == 1
    assert ruido.iloc[0]["duracao_min"] == 95.0
    assert ruido.iloc[0]["mediana_duracao"] == pytest.approx(28, abs=1)


def test_viagens_parecidas_nao_viram_ruido():
    marcadas = dbscan.marcar_ruido(viagens_artificiais())
    assert marcadas["ruido"].mean() < 0.05


def test_cada_sentido_e_agrupado_separado():
    marcadas = dbscan.marcar_ruido(viagens_artificiais())
    assert set(marcadas.groupby("sentido")["mediana_duracao"].first().round()) == {28.0, 32.0}


def test_poucas_viagens_da_erro_claro():
    with pytest.raises(ValueError, match="pelo menos"):
        dbscan.marcar_ruido(viagens_artificiais().head(20))

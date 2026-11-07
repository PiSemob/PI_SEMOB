from datetime import date

import pytest

from app.agente import tools
from app.agente.ferramentas.base import Limites, validar_linha, validar_periodo

LIMITES = Limites(date(2026, 7, 1), date(2026, 9, 14), ("01", "02", "04"))


def test_periodo_e_cortado_nos_dias_com_dados():
    assert validar_periodo("2026-06-15", "2026-07-10", LIMITES) == (date(2026, 7, 1), date(2026, 7, 10))


@pytest.mark.parametrize(
    "inicio, fim, mensagem",
    [
        ("2026-08-10", "2026-08-01", "início é depois"),
        ("2025-01-01", "2025-01-31", "Não há dados"),
        ("01/08/2026", "2026-08-31", "Data inválida"),
    ],
)
def test_periodos_invalidos(inicio, fim, mensagem):
    with pytest.raises(ValueError, match=mensagem):
        validar_periodo(inicio, fim, LIMITES)


def test_limite_de_dias_por_analise():
    with pytest.raises(ValueError, match="até 31 dias"):
        validar_periodo("2026-07-01", "2026-08-31", LIMITES, 31)


def test_linha_inexistente_e_recusada():
    assert validar_linha(4, LIMITES) == "04"
    assert validar_linha(None, LIMITES) is None
    with pytest.raises(ValueError, match="não existe"):
        validar_linha("99", LIMITES)


def test_executar_recusa_ferramenta_e_parametros_desconhecidos():
    with pytest.raises(ValueError, match="desconhecida"):
        tools.executar("apagar_tudo", {}, None, LIMITES)
    with pytest.raises(ValueError, match="não aceitos"):
        tools.executar("resumo_operacao", {"inicio": "2026-08-01", "fim": "2026-08-02", "sql": "x"}, None, LIMITES)
    with pytest.raises(ValueError, match="Faltam"):
        tools.executar("resumo_operacao", {"inicio": "2026-08-01"}, None, LIMITES)
    with pytest.raises(TypeError):
        tools.executar("resumo_operacao", "inicio=2026-08-01", None, LIMITES)

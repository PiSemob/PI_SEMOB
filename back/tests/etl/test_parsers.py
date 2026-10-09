from pathlib import Path

from app.etl.parsers.leitura import contexto_do_caminho, ler_arquivo
from app.etl.parsers.tipos import TIPOS, identificar

BRUTOS = Path(__file__).resolve().parents[3] / "dados" / "brutos"
AGOSTO_MENSAL = BRUTOS / "Agosto_2026" / "Mensal"


def test_identifica_pelo_titulo_inteiro():
    assert identificar("Mensal - Viagens").chave == "viagens"
    assert identificar("Quinzenal - Viagens não Realizadas").chave == "viagens_nao_realizadas"
    assert identificar("São Caetano do Sul - Passageiros do Sistema").chave == "passageiros"
    assert identificar("Mensal - Relatório que não existe") is None


def test_contexto_vem_da_pasta():
    caminho = AGOSTO_MENSAL / "Mensal_202608.html"
    assert contexto_do_caminho(caminho) == (
        "2026-08",
        "mensal",
        "Agosto_2026/Mensal/Mensal_202608.html",
    )


def test_agosto_mensal_tem_os_12_tipos():
    encontrados = set()
    for caminho in sorted(AGOSTO_MENSAL.glob("*.html")):
        for relatorio in ler_arquivo(caminho):
            tipo = identificar(relatorio.titulo)
            assert tipo is not None, f"título desconhecido: {relatorio.titulo}"
            assert tuple(relatorio.tabela.columns) == tipo.colunas, relatorio.arquivo
            assert relatorio.gerado_em, relatorio.arquivo
            encontrados.add(tipo.chave)
    assert encontrados == {tipo.chave for tipo in TIPOS}


def test_todos_os_arquivos_sao_reconhecidos():
    arquivos = sorted(BRUTOS.rglob("*.html"))
    assert len(arquivos) == 44
    for caminho in arquivos:
        relatorios = ler_arquivo(caminho)
        assert relatorios, caminho.name
        for relatorio in relatorios:
            tipo = identificar(relatorio.titulo)
            assert tipo is not None, f"{relatorio.arquivo}: {relatorio.titulo}"
            assert tuple(relatorio.tabela.columns) == tipo.colunas, relatorio.arquivo


def test_viagens_de_agosto_saem_como_texto():
    (relatorio,) = ler_arquivo(AGOSTO_MENSAL / "Mensal_Viagens_202608.html")
    assert relatorio.titulo == "Mensal - Viagens"
    assert relatorio.gerado_em == "04/09/2026 08:00"
    assert len(relatorio.tabela) == 36752  
    primeira = relatorio.tabela.iloc[0]
    assert primeira["Linha"] == "01"  
    assert primeira["kmTotal"] == "6,5" 
from pathlib import Path

from app.etl.carga_bruta import gravar_bruto, montar_documentos
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import identificar

BRUTOS = Path(__file__).resolve().parents[3] / "dados" / "brutos"
ARQUIVO = BRUTOS / "Agosto_2026" / "Mensal" / "Mensal_Linhas_202608.html"


class ColecaoFalsa:
    """Imita o que a carga usa de uma coleção do MongoDB, guardando em uma lista."""

    def __init__(self):
        self.documentos = []

    def delete_many(self, filtro):
        self.documentos = [
            d for d in self.documentos if any(d.get(k) != v for k, v in filtro.items())
        ]

    def insert_many(self, documentos):
        self.documentos.extend(documentos)


class BancoFalso(dict):
    def __missing__(self, nome):
        self[nome] = ColecaoFalsa()
        return self[nome]


def test_documento_leva_os_metadados():
    (relatorio,) = ler_arquivo(ARQUIVO)
    documentos = montar_documentos(relatorio, identificar(relatorio.titulo))
    primeiro = documentos[0]
    assert primeiro["tipo"] == "resumo_linha"
    assert primeiro["periodo"] == "mensal"
    assert primeiro["mes_referencia"] == "2026-08"
    assert primeiro["arquivo_origem"] == "Agosto_2026/Mensal/Mensal_Linhas_202608.html"
    assert primeiro["gerado_em"] == "04/09/2026 08:00"
    assert primeiro["dados"] == {
        "Data": "01/08/2026", "Linha": "01", "kmTotal": "650", "nrViagens": "98",
    }


def test_carga_repetida_nao_duplica():
    (relatorio,) = ler_arquivo(ARQUIVO)
    tipo = identificar(relatorio.titulo)
    banco = BancoFalso()
    primeira = gravar_bruto(banco, relatorio, tipo)
    segunda = gravar_bruto(banco, relatorio, tipo)
    assert primeira == segunda == len(relatorio.tabela)
    assert len(banco["resumo_linha"].documentos) == primeira
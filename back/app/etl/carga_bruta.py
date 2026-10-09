# gravaçao no banco do parsers, usando metadados

"""Grava no MongoDB o que o parser leu, sem transformar nada.

Um documento por linha de relatório, em uma coleção por tipo. Cada documento
leva os metadados de origem, para sempre dar para saber de que arquivo veio.
"""

from app.etl.parsers.leitura import RelatorioLido
from app.etl.parsers.tipos import TipoRelatorio


def montar_documentos(relatorio: RelatorioLido, tipo: TipoRelatorio) -> list[dict]:
    """Transforma cada linha do relatório em um documento com metadados."""
    return [
        {
            "tipo": tipo.chave,
            "periodo": relatorio.periodo,
            "mes_referencia": relatorio.mes_referencia,
            "arquivo_origem": relatorio.arquivo,
            "gerado_em": relatorio.gerado_em,
            "dados": linha,
        }
        for linha in relatorio.tabela.to_dict("records")
    ]


def gravar_bruto(banco, relatorio: RelatorioLido, tipo: TipoRelatorio) -> int:
    """Grava um relatório na coleção do seu tipo e devolve quantos documentos entraram.

    Antes de inserir, apaga o que já veio do mesmo arquivo. Assim a carga pode
    ser repetida sem duplicar nada.
    """
    colecao = banco[tipo.chave]
    colecao.delete_many({"arquivo_origem": relatorio.arquivo})
    documentos = montar_documentos(relatorio, tipo)
    if documentos:
        colecao.insert_many(documentos)
    return len(documentos)
# roda ETL completo 

"""Roda o ETL: lê dados/brutos e grava o bruto no MongoDB.

Uso, de dentro de back/:  python -m scripts.ingerir
Pode ser rodado mais de uma vez sem duplicar nada.
"""

from app.config import PASTA_BRUTOS
from app.db.mongo import banco_bruto
from app.etl.carga_bruta import gravar_bruto
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import identificar


def carregar_bruto(banco) -> None:
    """Etapa 1: lê cada arquivo HTML e grava as linhas no MongoDB, como vieram."""
    arquivos = sorted(PASTA_BRUTOS.rglob("*.html"))
    print(f"Etapa 1 (bruto): {len(arquivos)} arquivos em {PASTA_BRUTOS}")
    for caminho in arquivos:
        for relatorio in ler_arquivo(caminho):
            tipo = identificar(relatorio.titulo)
            if tipo is None:
                print(f"  AVISO: título desconhecido em {relatorio.arquivo}: {relatorio.titulo}")
                continue
            if tuple(relatorio.tabela.columns) != tipo.colunas:
                print(f"  AVISO: colunas diferentes do esperado em {relatorio.arquivo}")
                continue
            quantidade = gravar_bruto(banco, relatorio, tipo)
            print(f"  {relatorio.arquivo} -> {tipo.chave}: {quantidade}")


def main() -> None:
    carregar_bruto(banco_bruto())


if __name__ == "__main__":
    main()
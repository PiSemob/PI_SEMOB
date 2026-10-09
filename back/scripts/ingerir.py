"""Roda o ETL completo: dados/brutos -> MongoDB (bruto) -> PostgreSQL (limpo).

Uso, de dentro de back/:  python -m scripts.ingerir
Pode ser rodado mais de uma vez sem duplicar nada.
"""

from app.config import PASTA_BRUTOS
from app.db.mongo import banco_bruto
from app.db.postgres import criar_engine
from app.db.tabelas import metadata
from app.etl.carga_bruta import gravar_bruto
from app.etl.limpeza import gravar, limpar_tudo, tabela_bruta
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import TIPOS, identificar


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


def carregar_limpo(banco) -> None:
    """Etapa 2: lê o bruto do MongoDB, limpa e grava no PostgreSQL."""
    print("Etapa 2 (limpo):")
    tipos = {tipo.chave: tipo for tipo in TIPOS}

    def ler(chave: str):
        return tabela_bruta(banco[chave].find({}, {"_id": 0}), tipos[chave])

    limpas = limpar_tudo(ler)
    with criar_engine().begin() as conexao:
        for nome, df in limpas.items():
            quantidade = gravar(conexao, metadata.tables[nome], df)
            suspeitos = int(df["suspeito"].sum())
            print(f"  {nome}: {quantidade} registros, {suspeitos} suspeitos")


def main() -> None:
    banco = banco_bruto()
    carregar_bruto(banco)
    carregar_limpo(banco)


if __name__ == "__main__":
    main()
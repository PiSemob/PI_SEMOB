#cria tabelas do postgre

"""Cria no PostgreSQL as tabelas definidas em app/db/tabelas.py.

Uso, de dentro de back/:  python -m scripts.criar_tabelas
Pode ser rodado mais de uma vez: tabela que já existe não é alterada.
"""

from app.db.postgres import criar_engine
from app.db.tabelas import metadata
from app.db.tabelas_app import metadata_app


def main() -> None:
    engine = criar_engine()
    metadata.create_all(engine)
    for nome in metadata.tables:
        print(f"tabela pronta: {nome}")
    metadata_app.create_all(engine)
    for nome in metadata_app.tables:
        print(f"tabela do app pronta: {nome}")


if __name__ == "__main__":
    main()

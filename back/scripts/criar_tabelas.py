#cria tabelas do postgre

"""Cria no PostgreSQL as tabelas definidas em app/db/tabelas.py.

Uso, de dentro de back/:  python -m scripts.criar_tabelas
Pode ser rodado mais de uma vez: tabela que já existe não é alterada.
"""

from app.db.postgres import criar_engine
from app.db.tabelas import metadata


def main() -> None:
    engine = criar_engine()
    metadata.create_all(engine)
    for nome in metadata.tables:
        print(f"tabela pronta: {nome}")


if __name__ == "__main__":
    main()
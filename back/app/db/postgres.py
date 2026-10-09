# conexao com a camada limpa

"""Conexão com a camada limpa (PostgreSQL)."""

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from app.config import config


def criar_engine() -> Engine:
    """Devolve o objeto de conexão do SQLAlchemy com o PostgreSQL do .env."""
    return create_engine(config.postgres_url)
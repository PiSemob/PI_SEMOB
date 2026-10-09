# conexão com a camada bruta

"""Conexão com a camada bruta (MongoDB)."""

from pymongo import MongoClient
from pymongo.database import Database

from app.config import config


def banco_bruto() -> Database:
    """Devolve o banco do MongoDB onde ficam os relatórios como vieram."""
    return MongoClient(config.mongo_url)[config.mongo_db]
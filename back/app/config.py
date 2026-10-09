# leitura de env 

"""Configurações do back, lidas do arquivo .env da raiz do repositório.

Nenhum outro arquivo lê variável de ambiente diretamente: todos importam `config`.
"""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

RAIZ = Path(__file__).resolve().parents[2]  
PASTA_BRUTOS = RAIZ / "dados" / "brutos"


class Configuracoes(BaseSettings):
    model_config = SettingsConfigDict(env_file=RAIZ / ".env", extra="ignore")
    postgres_url: str
    mongo_url: str = "mongodb://localhost:27017"
    mongo_db: str = "semob"
    jev_api_key: str = ""
    llm_api_key: str = ""


config = Configuracoes()
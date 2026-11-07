# leitura de env

"""Configurações do back, lidas do arquivo .env da raiz do repositório.

Nenhum outro arquivo lê variável de ambiente diretamente: todos importam `config`.
"""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

RAIZ = Path(__file__).resolve().parents[2]
BACK = RAIZ / "back"
PASTA_BRUTOS = RAIZ / "dados" / "brutos"
PASTA_DOCUMENTOS = RAIZ / "dados" / "documentos"
PASTA_MODELOS = BACK / "modelos"
PASTA_EMAILS = BACK / "emails"


class Configuracoes(BaseSettings):
    model_config = SettingsConfigDict(env_file=RAIZ / ".env", extra="ignore")
    postgres_url: str
    mongo_url: str = "mongodb://localhost:27017"
    mongo_db: str = "semob"
    jev_api_key: str = ""

    front_url: str = "http://localhost:5555"
    sessao_horas: int = 12
    link_senha_minutos: int = 60
    convite_horas: int = 72

    smtp_host: str = ""
    smtp_porta: int = 587
    smtp_usuario: str = ""
    smtp_senha: str = ""
    smtp_remetente: str = "ferret@semob.local"


config = Configuracoes()

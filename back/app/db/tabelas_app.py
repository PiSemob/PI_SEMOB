from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    MetaData,
    String,
    Table,
    Text,
)

metadata_app = MetaData()

usuarios = Table(
    "usuarios",
    metadata_app,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("email", String(200), nullable=False, unique=True),
    Column("nome", String(200), nullable=False),
    Column("senha_hash", Text),
    Column("admin", Boolean, nullable=False, default=False),
    Column("ativo", Boolean, nullable=False, default=True),
    Column("criado_em", DateTime, nullable=False),
)

sessoes = Table(
    "sessoes",
    metadata_app,
    Column("token_hash", String(64), primary_key=True),
    Column("usuario_id", Integer, ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
    Column("criada_em", DateTime, nullable=False),
    Column("expira_em", DateTime, nullable=False),
)

tokens_senha = Table(
    "tokens_senha",
    metadata_app,
    Column("token_hash", String(64), primary_key=True),
    Column("usuario_id", Integer, ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
    Column("criado_em", DateTime, nullable=False),
    Column("expira_em", DateTime, nullable=False),
    Column("usado_em", DateTime),
)

configuracoes = Table(
    "configuracoes",
    metadata_app,
    Column("chave", String(60), primary_key=True),
    Column("valor", Text, nullable=False),
    Column("atualizado_em", DateTime, nullable=False),
)

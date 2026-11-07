import json
from datetime import datetime

from sqlalchemy import delete, insert, select
from sqlalchemy.engine import Connection

from app.db.tabelas_app import configuracoes

PADRAO: dict = {
    "organizacao": "SEMOB-SCS",
    "cidade": "São Caetano do Sul",
    "alertas_anomalia": True,
    "relatorios_automaticos": False,
    "email_relatorios": "",
}


class ErroConfiguracao(ValueError):
    pass


def ler(conexao: Connection) -> dict:
    salvas = {
        linha.chave: json.loads(linha.valor)
        for linha in conexao.execute(select(configuracoes.c.chave, configuracoes.c.valor))
    }
    return {chave: salvas.get(chave, padrao) for chave, padrao in PADRAO.items()}


def _validar(chave: str, valor) -> None:
    if chave not in PADRAO:
        raise ErroConfiguracao(f"Configuração desconhecida: {chave}.")
    if not isinstance(valor, type(PADRAO[chave])):
        raise ErroConfiguracao(f"Valor inválido para {chave}.")
    if chave in ("organizacao", "cidade") and not valor.strip():
        raise ErroConfiguracao("Organização e cidade não podem ficar vazias.")
    if chave == "email_relatorios" and valor.strip() and "@" not in valor:
        raise ErroConfiguracao("Informe um e-mail válido para os relatórios automáticos.")


def salvar(conexao: Connection, mudancas: dict) -> dict:
    for chave, valor in mudancas.items():
        _validar(chave, valor)
    agora = datetime.now()
    for chave, valor in mudancas.items():
        valor = valor.strip() if isinstance(valor, str) else valor
        conexao.execute(delete(configuracoes).where(configuracoes.c.chave == chave))
        conexao.execute(insert(configuracoes).values(chave=chave, valor=json.dumps(valor), atualizado_em=agora))
    conexao.commit()
    return ler(conexao)

import logging
import re
import smtplib
from dataclasses import dataclass
from datetime import datetime
from email.message import EmailMessage
from pathlib import Path

from app.config import PASTA_EMAILS, config

log = logging.getLogger(__name__)


@dataclass
class Anexo:
    nome: str
    conteudo: bytes
    tipo: str


def _montar(para: str, assunto: str, texto: str, anexos: list[Anexo]) -> EmailMessage:
    mensagem = EmailMessage()
    mensagem["From"] = config.smtp_remetente
    mensagem["To"] = para
    mensagem["Subject"] = assunto
    mensagem.set_content(texto)
    for anexo in anexos:
        principal, secundario = anexo.tipo.split("/", 1)
        mensagem.add_attachment(
            anexo.conteudo, maintype=principal, subtype=secundario, filename=anexo.nome
        )
    return mensagem


def enviar_email(para: str, assunto: str, texto: str, anexos: list[Anexo] | None = None) -> Path | None:
    mensagem = _montar(para, assunto, texto, anexos or [])

    if config.smtp_host:
        with smtplib.SMTP(config.smtp_host, config.smtp_porta, timeout=30) as servidor:
            servidor.starttls()
            if config.smtp_usuario:
                servidor.login(config.smtp_usuario, config.smtp_senha)
            servidor.send_message(mensagem)
        log.info("e-mail enviado para %s: %s", para, assunto)
        return None

    PASTA_EMAILS.mkdir(parents=True, exist_ok=True)
    nome = re.sub(r"[^a-z0-9]+", "-", assunto.lower()).strip("-")[:50]
    caminho = PASTA_EMAILS / f"{datetime.now():%Y%m%d-%H%M%S-%f}_{nome}.eml"
    caminho.write_bytes(bytes(mensagem))
    log.warning("SMTP não configurado: e-mail para %s gravado em %s", para, caminho)
    print(f"[e-mail] SMTP não configurado. Mensagem para {para} gravada em {caminho}")
    return caminho

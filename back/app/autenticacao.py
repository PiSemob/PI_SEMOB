import hashlib
import hmac
import re
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import delete, insert, select, update
from sqlalchemy.engine import Connection

from app.config import config
from app.correio import enviar_email
from app.db.tabelas_app import sessoes, tokens_senha, usuarios

ITERACOES = 240_000
SENHA_MINIMA = 8
EMAIL_VALIDO = re.compile(r"[^@\s]+@[^@\s]+\.[^@\s]+")


class ErroAutenticacao(ValueError):
    pass


@dataclass
class Usuario:
    id: int
    email: str
    nome: str
    admin: bool = False


def gerar_hash(senha: str) -> str:
    sal = secrets.token_bytes(16)
    resumo = hashlib.pbkdf2_hmac("sha256", senha.encode(), sal, ITERACOES)
    return f"pbkdf2_sha256${ITERACOES}${sal.hex()}${resumo.hex()}"


def conferir_senha(senha: str, guardado: str | None) -> bool:
    try:
        _, iteracoes, sal, resumo = (guardado or "").split("$")
    except ValueError:
        return False
    calculado = hashlib.pbkdf2_hmac("sha256", senha.encode(), bytes.fromhex(sal), int(iteracoes))
    return hmac.compare_digest(calculado.hex(), resumo)


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _normalizar(email: str) -> str:
    return email.strip().lower()


def _validar_senha(senha: str) -> None:
    if len(senha) < SENHA_MINIMA:
        raise ErroAutenticacao(f"A senha precisa ter pelo menos {SENHA_MINIMA} caracteres.")


def _usuario(linha) -> Usuario:
    return Usuario(linha["id"], linha["email"], linha["nome"], bool(linha["admin"]))


def novo_usuario(conexao: Connection, email: str, nome: str, senha_hash: str | None, admin: bool) -> Usuario:
    email = _normalizar(email)
    if not EMAIL_VALIDO.fullmatch(email):
        raise ErroAutenticacao("Informe um e-mail válido.")
    if conexao.scalar(select(usuarios.c.id).where(usuarios.c.email == email)) is not None:
        raise ErroAutenticacao("Já existe um usuário com este e-mail.")
    nome = nome.strip() or email
    novo_id = conexao.execute(
        insert(usuarios).values(
            email=email, nome=nome, senha_hash=senha_hash, admin=admin, ativo=True, criado_em=datetime.now(),
        )
    ).inserted_primary_key[0]
    return Usuario(novo_id, email, nome, admin)


def criar_usuario(conexao: Connection, email: str, nome: str, senha: str, admin: bool = False) -> Usuario:
    _validar_senha(senha)
    usuario = novo_usuario(conexao, email, nome, gerar_hash(senha), admin)
    conexao.commit()
    return usuario


def emitir_link(conexao: Connection, usuario_id: int, validade: timedelta, rota: str) -> str:
    token = secrets.token_urlsafe(32)
    agora = datetime.now()
    conexao.execute(
        insert(tokens_senha).values(
            token_hash=_hash_token(token), usuario_id=usuario_id, criado_em=agora, expira_em=agora + validade,
        )
    )
    return f"{config.front_url.rstrip('/')}/#/{rota}?token={token}"


def _buscar_por_email(conexao: Connection, email: str):
    return conexao.execute(
        select(usuarios).where(usuarios.c.email == _normalizar(email), usuarios.c.ativo.is_(True))
    ).mappings().first()


def entrar(conexao: Connection, email: str, senha: str) -> tuple[str, Usuario]:
    linha = _buscar_por_email(conexao, email)
    if linha is None or not conferir_senha(senha, linha["senha_hash"]):
        raise ErroAutenticacao("E-mail ou senha incorretos.")
    token = secrets.token_urlsafe(32)
    agora = datetime.now()
    conexao.execute(delete(sessoes).where(sessoes.c.expira_em < agora))
    conexao.execute(
        insert(sessoes).values(
            token_hash=_hash_token(token), usuario_id=linha["id"], criada_em=agora,
            expira_em=agora + timedelta(hours=config.sessao_horas),
        )
    )
    conexao.commit()
    return token, _usuario(linha)


def usuario_da_sessao(conexao: Connection, token: str) -> Usuario | None:
    linha = conexao.execute(
        select(usuarios.c.id, usuarios.c.email, usuarios.c.nome, usuarios.c.admin)
        .select_from(sessoes.join(usuarios, sessoes.c.usuario_id == usuarios.c.id))
        .where(
            sessoes.c.token_hash == _hash_token(token),
            sessoes.c.expira_em > datetime.now(),
            usuarios.c.ativo.is_(True),
        )
    ).mappings().first()
    return _usuario(linha) if linha else None


def sair(conexao: Connection, token: str) -> None:
    conexao.execute(delete(sessoes).where(sessoes.c.token_hash == _hash_token(token)))
    conexao.commit()


def pedir_recuperacao(conexao: Connection, email: str) -> None:
    linha = _buscar_por_email(conexao, email)
    if linha is None:
        return
    link = emitir_link(
        conexao, linha["id"], timedelta(minutes=config.link_senha_minutos), "redefinir-senha"
    )
    conexao.commit()
    enviar_email(
        linha["email"],
        "Ferret: redefinição de senha",
        f"Olá, {linha['nome']}.\n\n"
        f"Recebemos um pedido para criar uma senha nova no Ferret.\n"
        f"Abra o link abaixo em até {config.link_senha_minutos} minutos:\n\n{link}\n\n"
        "Se você não pediu, ignore este e-mail: sua senha continua a mesma.\n",
    )


def redefinir_senha(conexao: Connection, token: str, senha: str) -> None:
    _validar_senha(senha)
    agora = datetime.now()
    linha = conexao.execute(
        select(tokens_senha).where(
            tokens_senha.c.token_hash == _hash_token(token),
            tokens_senha.c.usado_em.is_(None),
            tokens_senha.c.expira_em > agora,
        )
    ).mappings().first()
    if linha is None:
        raise ErroAutenticacao("Este link é inválido ou expirou. Peça um novo.")
    conexao.execute(
        update(usuarios).where(usuarios.c.id == linha["usuario_id"]).values(senha_hash=gerar_hash(senha))
    )
    conexao.execute(
        update(tokens_senha)
        .where(tokens_senha.c.usuario_id == linha["usuario_id"], tokens_senha.c.usado_em.is_(None))
        .values(usado_em=agora)
    )
    conexao.execute(delete(sessoes).where(sessoes.c.usuario_id == linha["usuario_id"]))
    conexao.commit()

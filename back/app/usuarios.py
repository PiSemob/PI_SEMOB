from datetime import timedelta

from sqlalchemy import delete, select, update
from sqlalchemy.engine import Connection

from app.autenticacao import ErroAutenticacao, Usuario, emitir_link, novo_usuario
from app.config import config
from app.correio import enviar_email
from app.db.tabelas_app import sessoes, tokens_senha, usuarios


class UsuarioNaoEncontrado(LookupError):
    pass


_CONSULTA = select(
    usuarios.c.id,
    usuarios.c.email,
    usuarios.c.nome,
    usuarios.c.admin,
    usuarios.c.senha_hash.is_(None).label("pendente"),
    usuarios.c.criado_em,
).where(usuarios.c.ativo.is_(True))


def listar(conexao: Connection) -> list[dict]:
    return [dict(linha) for linha in conexao.execute(_CONSULTA.order_by(usuarios.c.nome)).mappings()]


def _buscar(conexao: Connection, usuario_id: int) -> dict:
    linha = conexao.execute(_CONSULTA.where(usuarios.c.id == usuario_id)).mappings().first()
    if linha is None:
        raise UsuarioNaoEncontrado("Usuário não encontrado.")
    return dict(linha)


def _proteger_a_si_mesmo(usuario_id: int, quem: Usuario, acao: str) -> None:
    if usuario_id == quem.id:
        raise ErroAutenticacao(f"Você não pode {acao} o seu próprio acesso.")


def _enviar_convite(conexao: Connection, usuario: dict, quem: Usuario) -> None:
    link = emitir_link(conexao, usuario["id"], timedelta(hours=config.convite_horas), "criar-senha")
    conexao.commit()
    enviar_email(
        usuario["email"],
        "Ferret: convite de acesso",
        f"Olá, {usuario['nome']}.\n\n"
        f"{quem.nome} cadastrou você no Ferret, a plataforma de dados do transporte municipal da SEMOB.\n"
        f"Para entrar, crie a sua senha pelo link abaixo em até {config.convite_horas} horas:\n\n{link}\n\n"
        "Depois, use o seu e-mail e essa senha na tela de login.\n",
    )


def convidar(conexao: Connection, email: str, nome: str, admin: bool, quem: Usuario) -> dict:
    novo = novo_usuario(conexao, email, nome, None, admin)
    usuario = _buscar(conexao, novo.id)
    _enviar_convite(conexao, usuario, quem)
    return usuario


def reenviar_convite(conexao: Connection, usuario_id: int, quem: Usuario) -> None:
    usuario = _buscar(conexao, usuario_id)
    if not usuario["pendente"]:
        raise ErroAutenticacao("Esta pessoa já criou a senha. Se esqueceu, ela pode usar \"Esqueci minha senha\".")
    conexao.execute(
        delete(tokens_senha).where(tokens_senha.c.usuario_id == usuario_id, tokens_senha.c.usado_em.is_(None))
    )
    _enviar_convite(conexao, usuario, quem)


def definir_admin(conexao: Connection, usuario_id: int, admin: bool, quem: Usuario) -> dict:
    _proteger_a_si_mesmo(usuario_id, quem, "mudar")
    _buscar(conexao, usuario_id)
    conexao.execute(update(usuarios).where(usuarios.c.id == usuario_id).values(admin=admin))
    conexao.commit()
    return _buscar(conexao, usuario_id)


def remover(conexao: Connection, usuario_id: int, quem: Usuario) -> None:
    _proteger_a_si_mesmo(usuario_id, quem, "remover")
    _buscar(conexao, usuario_id)
    conexao.execute(delete(sessoes).where(sessoes.c.usuario_id == usuario_id))
    conexao.execute(delete(tokens_senha).where(tokens_senha.c.usuario_id == usuario_id))
    conexao.execute(delete(usuarios).where(usuarios.c.id == usuario_id))
    conexao.commit()

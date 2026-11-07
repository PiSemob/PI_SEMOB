import argparse
import getpass
import sys

from app.autenticacao import ErroAutenticacao, criar_usuario
from app.db.postgres import criar_engine
from app.db.tabelas_app import metadata_app


def main() -> None:
    parser = argparse.ArgumentParser(description="Cadastra um usuário do Ferret.")
    parser.add_argument("email")
    parser.add_argument("nome")
    parser.add_argument("--senha", help="senha (se omitida, é pedida no terminal)")
    parser.add_argument("--admin", action="store_true", help="pode convidar e remover usuários na tela Usuários")
    args = parser.parse_args()

    senha = args.senha
    if senha is None:
        senha = getpass.getpass("Senha: ")
        if getpass.getpass("Repita a senha: ") != senha:
            sys.exit("As senhas não são iguais.")

    engine = criar_engine()
    metadata_app.create_all(engine)
    with engine.connect() as conexao:
        try:
            usuario = criar_usuario(conexao, args.email, args.nome, senha, args.admin)
        except ErroAutenticacao as erro:
            sys.exit(str(erro))
    perfil = "administrador" if usuario.admin else "usuário"
    print(f"{perfil} criado: {usuario.email} ({usuario.nome})")


if __name__ == "__main__":
    main()

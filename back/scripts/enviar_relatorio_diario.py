from datetime import timedelta

from sqlalchemy import func, select

from app import configuracoes
from app.correio import Anexo, enviar_email
from app.db import tabelas
from app.db.postgres import criar_engine
from app.db.tabelas_app import metadata_app, usuarios
from app.formatos import data_br
from app.relatorios import exportacao, montagem

DIAS = 7


def main() -> None:
    engine = criar_engine()
    metadata_app.create_all(engine)
    with engine.connect() as conexao:
        ajustes = configuracoes.ler(conexao)
        if not ajustes["relatorios_automaticos"]:
            print("Relatórios automáticos estão desligados nas Configurações. Nada enviado.")
            return
        fim = conexao.scalar(select(func.max(tabelas.resumo_geral.c.data)))
        if fim is None:
            print("Não há dados carregados. Nada enviado.")
            return
        inicio = fim - timedelta(days=DIAS - 1)
        destinatarios = (
            [ajustes["email_relatorios"]]
            if ajustes["email_relatorios"]
            else list(conexao.scalars(select(usuarios.c.email).where(usuarios.c.ativo.is_(True))))
        )
        if not destinatarios:
            print("Nenhum destinatário: configure o e-mail ou cadastre usuários. Nada enviado.")
            return
        relatorio = montagem.montar("executivo", inicio, fim, conexao)

    pdf = Anexo(exportacao.nome_do_arquivo(relatorio, "pdf"), exportacao.para_pdf(relatorio), "application/pdf")
    texto = (
        f"Relatório Executivo de {data_br(inicio)} a {data_br(fim)}.\n\n"
        f"{relatorio['resumo']}\n\nO relatório completo está em anexo.\n\nFerret · {ajustes['organizacao']}"
    )
    for email in destinatarios:
        enviar_email(email, f"Ferret: Relatório Executivo {data_br(inicio)} a {data_br(fim)}", texto, [pdf])
        print(f"enviado para {email}")


if __name__ == "__main__":
    main()

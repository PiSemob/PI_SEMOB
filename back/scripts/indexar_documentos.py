#carrega docs do banco vetorial

from app.config import PASTA_DOCUMENTOS
from app.db import vetorial


def main() -> None:
    indice = vetorial.construir()
    if not indice.trechos:
        print(f"Nenhum documento .txt ou .md em {PASTA_DOCUMENTOS}. Nada a indexar.")
        return
    vetorial.salvar(indice)
    documentos = sorted({t.documento for t in indice.trechos})
    print(f"{len(indice.trechos)} trechos de {len(documentos)} documentos indexados:")
    for nome in documentos:
        print(f"  {nome}")
    print(f"índice salvo em {vetorial.ARQUIVO_INDICE}")


if __name__ == "__main__":
    main()

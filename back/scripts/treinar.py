#compara os modelos de previsão e salva a escolha em back/modelos/

"""Compara Prophet e SARIMAX em cada série e grava qual usar.

Uso, de dentro de back/:  python -m scripts.treinar
O resultado vai para back/modelos/escolhas.json, que fica fora do Git.
"""

import json
from datetime import datetime

from app.ml import dados
from app.ml.planejamento import avaliacao, previsao


def series_do_projeto() -> list[tuple[str, str | None]]:
    """Passageiros do sistema, e viagens e km do sistema e de cada linha."""
    series = [("passageiros", None), ("viagens", None), ("km", None)]
    for linha in dados.ler_linhas(minimo_de_dias=avaliacao.DIAS_DE_TESTE * 3):
        series += [("viagens", linha), ("km", linha)]
    return series


def main() -> None:
    escolhas = {}
    print(f"{'série':<22}{'prophet (MAE / MAPE)':>24}{'sarimax (MAE / MAPE)':>24}   escolhido")
    for nome, linha in series_do_projeto():
        erros = previsao.comparar(dados.ler_serie(nome, linha))
        escolhido = previsao.escolher(erros)
        escolhas[previsao.chave(nome, linha)] = {"modelo": escolhido, "erros": erros}
        colunas = "".join(
            f"{erros[modelo]['mae']:>14.1f} / {erros[modelo]['mape']:>5.1f}%"
            for modelo in ("prophet", "sarimax")
        )
        print(f"{previsao.chave(nome, linha):<22}{colunas}   {escolhido}")

    previsao.ARQUIVO_DE_ESCOLHAS.parent.mkdir(exist_ok=True)
    conteudo = {
        "treinado_em": datetime.now().isoformat(timespec="seconds"),
        "dias_de_teste": avaliacao.DIAS_DE_TESTE,
        "series": escolhas,
    }
    previsao.ARQUIVO_DE_ESCOLHAS.write_text(
        json.dumps(conteudo, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"\n{len(escolhas)} séries comparadas. Escolhas gravadas em {previsao.ARQUIVO_DE_ESCOLHAS}")


if __name__ == "__main__":
    main()

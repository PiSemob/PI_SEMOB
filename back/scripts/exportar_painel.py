"""Gera o arquivo de dados do app a partir dos relatórios em dados/brutos.

Uso, de dentro de back/:  python -m scripts.exportar_painel

Usa o mesmo ETL do `ingerir` (leitura e limpeza), mas em memória: não precisa
do MongoDB, do PostgreSQL nem do .env. O resultado vai para
front/assets/dados/painel.json e é o que as telas do app mostram enquanto a
API não estiver pronta.
"""

import json
from collections import defaultdict
from datetime import date
from pathlib import Path

import pandas as pd

from app.etl.carga_bruta import montar_documentos
from app.etl.limpeza import limpar_tudo, tabela_bruta
from app.etl.parsers.leitura import ler_arquivo
from app.etl.parsers.tipos import TIPOS, identificar

RAIZ = Path(__file__).resolve().parents[2]
PASTA_BRUTOS = RAIZ / "dados" / "brutos"
SAIDA = RAIZ / "front" / "assets" / "dados" / "painel.json"

# Nome e bairro de cada linha, tirados do campo "atendimento" dos relatórios de
# viagens não realizadas/iniciadas/terminadas. A origem é a Estação São
# Caetano, menos na linha 11, que sai do Fórum (no Centro).
LINHAS = {
    "01": ("Estação – Santa Maria", "Estação São Caetano", "Santa Maria"),
    "02": ("Circular Gerty", "Estação São Caetano", "Nova Gerty"),
    "03": ("Barcelona Circular", "Estação São Caetano", "Barcelona"),
    "04": ("Estação – Santa Paula", "Estação São Caetano", "Santa Paula"),
    "05": ("Estação – Mauá", "Estação São Caetano", "Mauá"),
    "06": ("Estação – Nova Gerty", "Estação São Caetano", "Nova Gerty"),
    "07": ("Estação – Boa Vista", "Estação São Caetano", "Boa Vista"),
    "08": ("Estação via Fundação – Prosperidade", "Estação São Caetano", "Prosperidade"),
    "10": ("Estação – Oswaldo Cruz", "Estação São Caetano", "Oswaldo Cruz"),
    "11": ("Fórum – Santa Maria", "Centro", "Santa Maria"),
}


def ler_relatorios() -> tuple[dict[str, pd.DataFrame], list[dict]]:
    """Lê todos os HTMLs, limpa com o ETL do back e lista os arquivos lidos."""
    documentos: dict[str, list[dict]] = defaultdict(list)
    arquivos = []
    for caminho in sorted(PASTA_BRUTOS.rglob("*.html")):
        tipos_do_arquivo = []
        registros = 0
        gerado_em = periodo = mes = ""
        for relatorio in ler_arquivo(caminho):
            tipo = identificar(relatorio.titulo)
            if tipo is None or tuple(relatorio.tabela.columns) != tipo.colunas:
                continue
            novos = montar_documentos(relatorio, tipo)
            documentos[tipo.chave].extend(novos)
            tipos_do_arquivo.append(tipo.titulo)
            registros += len(novos)
            gerado_em, periodo, mes = relatorio.gerado_em, relatorio.periodo, relatorio.mes_referencia
        arquivos.append({
            "arquivo": caminho.name,
            "pasta": caminho.parent.relative_to(PASTA_BRUTOS).as_posix(),
            "mes_referencia": mes,
            "periodo": periodo,
            "gerado_em": gerado_em,
            "relatorios": tipos_do_arquivo,
            "registros": registros,
        })
    por_chave = {tipo.chave: tipo for tipo in TIPOS}
    limpas = limpar_tudo(lambda chave: tabela_bruta(documentos[chave], por_chave[chave]))
    return limpas, arquivos


def _numero(valor):
    """Converte para tipos do JSON; vazio vira None."""
    if valor is None or pd.isna(valor):
        return None
    if isinstance(valor, float) and valor.is_integer():
        return int(valor)
    if hasattr(valor, "item"):
        return valor.item()
    return valor


def montar_painel(limpas: dict[str, pd.DataFrame], arquivos: list[dict]) -> dict:
    geral = limpas["resumo_geral"].set_index("data")
    fcv = limpas["fcv"].set_index("data")
    passageiros = limpas["passageiros"].set_index("data")
    vendas = limpas["vendas"].set_index("data")
    saldos = limpas["saldos"].groupby("data")["saldo_final"].sum()

    datas = sorted(set(geral.index) | set(passageiros.index) | set(vendas.index))
    diario = []
    for d in datas:
        def campo(df, coluna):
            return _numero(df.at[d, coluna]) if d in df.index else None

        diario.append({
            "data": d.isoformat(),
            "dia_sem": d.weekday(),  # 0 = segunda
            "veiculos": campo(geral, "nr_veiculos"),
            "viagens_programadas": campo(geral, "nr_viagens_progr"),
            "viagens_realizadas": campo(geral, "nr_viagens_realiz"),
            "km_produtivo": campo(geral, "km_prod"),
            "km_improdutivo": campo(geral, "km_improd"),
            "km_total": campo(geral, "km_total"),
            "fcv": {p: [campo(fcv, f"{p}_p"), campo(fcv, f"{p}_r")] for p in ("manha", "tarde", "noite")},
            "catraca": campo(passageiros, "catraca"),
            "antecipados": campo(passageiros, "antecipados"),
            "nao_pagantes": campo(passageiros, "nao_pagantes"),
            "passageiros": campo(passageiros, "total"),
            "vendas": campo(vendas, "total_vendas"),
            "utilizacao": campo(vendas, "total_utilizacao"),
            "credito_circulante": campo(vendas, "credito_circulante"),
            "saldo_cartoes": _numero(saldos.get(d)),
        })

    resumo_linha = limpas["resumo_linha"]
    linha_dia = [
        {"data": r.data.isoformat(), "linha": r.linha, "km": _numero(r.km_total), "viagens": _numero(r.nr_viagens)}
        for r in resumo_linha.sort_values(["data", "linha"]).itertuples()
    ]

    # Viagens médias por faixa horária e dia da semana, por linha e no total.
    faixas = limpas["partidas_faixa_horaria"].copy()
    faixas["dia_sem"] = pd.to_datetime(faixas["data"]).dt.day_of_week
    dias_por_semana = faixas.groupby("dia_sem")["data"].nunique()
    por_linha = faixas.groupby(["linha", "dia_sem", "fx_hor"])["nr_viagens"].sum().reset_index()
    total = faixas.groupby(["dia_sem", "fx_hor"])["nr_viagens"].sum().reset_index()
    total["linha"] = ""
    faixa_horaria = [
        {
            "linha": r.linha,
            "dia_sem": int(r.dia_sem),
            "faixa": int(r.fx_hor),
            "viagens": round(float(r.nr_viagens) / int(dias_por_semana[r.dia_sem]), 1),
        }
        for r in pd.concat([por_linha, total]).itertuples()
    ]

    excecoes = limpas["viagens_excecao"].sort_values("inicio_programado", ascending=False)
    lista_excecoes = [
        {
            "data": r.data.isoformat(),
            "situacao": r.situacao,
            "linha": r.linha,
            "atendimento": r.atendimento,
            "sentido": r.sentido,
            "inicio_programado": None if pd.isna(r.inicio_programado) else r.inicio_programado.strftime("%H:%M"),
            "prefixo": None if pd.isna(r.prefixo) else str(r.prefixo),
        }
        for r in excecoes.itertuples()
    ]

    viagens = limpas["viagens"]
    totais_linha = resumo_linha.groupby("linha")[["km_total", "nr_viagens"]].sum()
    linhas = []
    for codigo, (nome, origem, destino) in LINHAS.items():
        da_linha = viagens[viagens["linha"] == codigo]
        linhas.append({
            "codigo": codigo,
            "nome": nome,
            "origem": origem,
            "destino": destino,
            "viagens": _numero(totais_linha.at[codigo, "nr_viagens"]) if codigo in totais_linha.index else 0,
            "km": _numero(round(totais_linha.at[codigo, "km_total"], 1)) if codigo in totais_linha.index else 0,
            "veiculos": int(da_linha["prefixo"].nunique()),
            "duracao_media_min": _numero(round(da_linha["duracao_min"].mean(), 1)),
        })

    bases = [
        {
            "tabela": nome,
            "registros": int(len(df)),
            "suspeitos": int(df["suspeito"].sum()),
            "inicio": df["data"].min().isoformat(),
            "fim": df["data"].max().isoformat(),
        }
        for nome, df in limpas.items()
    ]

    return {
        "gerado_em": date.today().isoformat(),
        "inicio": datas[0].isoformat(),
        "fim": datas[-1].isoformat(),
        "veiculos_distintos": int(viagens["prefixo"].nunique()),
        "linhas": linhas,
        "diario": diario,
        "linha_dia": linha_dia,
        "faixa_horaria": faixa_horaria,
        "excecoes": lista_excecoes,
        "arquivos": arquivos,
        "bases": bases,
    }


def main() -> None:
    limpas, arquivos = ler_relatorios()
    painel = montar_painel(limpas, arquivos)
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(json.dumps(painel, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{SAIDA.relative_to(RAIZ)}: {SAIDA.stat().st_size / 1024:.0f} KB, "
          f"{painel['inicio']} a {painel['fim']}, {len(arquivos)} arquivos")


if __name__ == "__main__":
    main()

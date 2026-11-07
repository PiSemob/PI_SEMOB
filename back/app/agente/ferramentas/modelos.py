from sqlalchemy.engine import Connection

from app.agente.ferramentas.base import (
    Limites,
    Resultado,
    indicador,
    tela,
    validar_linha,
    validar_periodo,
)
from app.api.dependencias import tabela_para_json
from app.formatos import data_br, decimal, inteiro, periodo_br, rotulo_periodo
from app.ml.fiscalizacao import dbscan, isolation_forest
from app.ml.planejamento import previsao

DIAS_ISOLATION_FOREST = 120
DIAS_DBSCAN = 31
MAXIMO_DE_EXEMPLOS = 15
AVISO = "Atípico não quer dizer irregular: quem confirma é a SEMOB."
ALVOS = ("passageiros", "viagens", "km")


def _celula(valor):
    if isinstance(valor, float):
        return round(valor, 2)
    if isinstance(valor, list):
        return ", ".join(str(v) for v in valor)
    if isinstance(valor, str) and len(valor) == 19 and valor[10] == "T":
        return f"{valor[8:10]}/{valor[5:7]} {valor[11:16]}"
    if isinstance(valor, str) and len(valor) == 10 and valor[4] == "-":
        return data_br(valor)
    return valor


def dias_atipicos(conexao: Connection, limites: Limites, inicio, fim, linha=None) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites, DIAS_ISOLATION_FOREST)
    linha = validar_linha(linha, limites)
    registros = tabela_para_json(isolation_forest.dias_atipicos(inicio, fim, linha))
    n = len(registros)
    if not n:
        alvo = f" na linha {linha}" if linha else ""
        texto = f"O Isolation Forest não apontou dias atípicos{alvo} {periodo_br(inicio, fim)}."
    else:
        achado = (f"{n} dia{'s' if n > 1 else ''} fora do padrão na linha {linha}" if linha
                  else f"{n} {'combinações' if n > 1 else 'combinação'} de dia e linha fora do padrão")
        primeiro = registros[0]
        destaque = _celula(primeiro.get("destaque"))
        texto = (
            f"O Isolation Forest apontou {achado} {periodo_br(inicio, fim)}. A mais atípica foi a linha "
            f"{primeiro['linha']} em {data_br(primeiro['data'])}" + (f" ({destaque})." if destaque else ".")
            + f" {AVISO}"
        )
    colunas = ("data", "linha", "nr_viagens", "km_total", "duracao_media", "pontuacao", "destaque")
    return Resultado(
        "dias_atipicos",
        {"modelo": "isolation_forest", "inicio": str(inicio), "fim": str(fim), "linha": linha,
         "quantidade": n, "anomalias": registros[:MAXIMO_DE_EXEMPLOS], "aviso": AVISO},
        texto,
        tela(f"Dias atípicos (Isolation Forest) · {rotulo_periodo(inicio, fim)}",
             [indicador("Dias e linhas atípicos", n)],
             ["Data", "Linha", "Viagens", "Km", "Duração média (min)", "Pontuação", "O que destoou"],
             [[_celula(r.get(c)) for c in colunas] for r in registros]),
    )


def viagens_atipicas(conexao: Connection, limites: Limites, inicio, fim, linha) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites, DIAS_DBSCAN)
    linha = validar_linha(linha, limites)
    if not linha:
        raise ValueError("Para procurar viagens atípicas, informe a linha.")
    registros = tabela_para_json(dbscan.viagens_atipicas(inicio, fim, linha))
    n = len(registros)
    if n:
        texto = (
            f"O DBSCAN encontrou {n} viage{'ns' if n > 1 else 'm'} da linha {linha} que não se parece{'m' if n > 1 else ''} "
            f"com nenhuma outra {periodo_br(inicio, fim)} (duração, quilometragem e horário). {AVISO}"
        )
    else:
        texto = f"O DBSCAN não encontrou viagens atípicas na linha {linha} {periodo_br(inicio, fim)}."
    return Resultado(
        "viagens_atipicas",
        {"modelo": "dbscan", "inicio": str(inicio), "fim": str(fim), "linha": linha, "quantidade": n,
         "anomalias": registros[:MAXIMO_DE_EXEMPLOS], "aviso": AVISO},
        texto,
        tela(f"Viagens atípicas da linha {linha} (DBSCAN) · {rotulo_periodo(inicio, fim)}",
             [indicador("Viagens atípicas", n)],
             ["Início", "Prefixo", "Sentido", "Duração (min)", "Km"],
             [[_celula(r.get("inicio_realizado")), r.get("prefixo"), r.get("sentido"),
               _celula(r.get("duracao_min")), _celula(r.get("km_total"))] for r in registros]),
    )


def prever(conexao: Connection, limites: Limites, alvo, linha=None, dias=7) -> Resultado:
    if alvo not in ALVOS:
        raise ValueError("Posso prever passageiros, viagens ou km.")
    linha = validar_linha(linha, limites)
    if alvo == "passageiros" and linha:
        raise ValueError("A base só tem passageiros do sistema inteiro, não por linha.")
    dias = max(1, min(int(dias or 7), 14))
    corpo = previsao.prever(alvo, dias, linha)
    pontos = corpo["previsao"]
    total = sum(p["previsto"] for p in pontos)
    erro = (corpo.get("erro_na_validacao") or {}).get("mape")
    onde = f"da linha {linha}" if linha else "do sistema"
    texto = (
        f"Para os próximos {len(pontos)} dias, a partir de {data_br(pontos[0]['data'])}, o modelo "
        f"{corpo['modelo'].upper()} prevê {decimal(total) if alvo == 'km' else inteiro(total)} {alvo} {onde}, "
        f"em média {decimal(total / len(pontos))} por dia."
        + (f" Nos testes com os últimos 14 dias, ele errou em média {decimal(erro)}%." if erro is not None else "")
    )
    return Resultado(
        "prever",
        corpo,
        texto,
        tela(f"Previsão de {alvo} {onde} · {dias} dias",
             [indicador("Modelo", corpo["modelo"].upper()),
              indicador("Total previsto", round(total, 1), alvo),
              indicador("Erro médio na validação", erro if erro is not None else "sem dado", "%")],
             ["Data", "Previsto", "Mínimo", "Máximo"],
             [[data_br(p["data"]), p["previsto"], p["minimo"], p["maximo"]] for p in pontos]),
    )

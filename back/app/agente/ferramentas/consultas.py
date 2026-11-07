from sqlalchemy import func, select
from sqlalchemy.engine import Connection

from app.agente.ferramentas.base import (
    Limites,
    Resultado,
    indicador,
    tela,
    validar_linha,
    validar_periodo,
)
from app.api import indicadores
from app.api.dependencias import linhas_da_consulta
from app.db import tabelas
from app.formatos import (
    data_br,
    decimal,
    inteiro,
    periodo_br,
    porcentagem,
    reais,
    rotulo_periodo,
)

SITUACOES = {
    "nao_realizada": "não realizada",
    "nao_iniciada": "não iniciada",
    "nao_terminada": "não terminada",
}
MAXIMO_DE_EXEMPLOS = 15


def sobre_os_dados(conexao: Connection, limites: Limites) -> Resultado:
    corpo = indicadores.periodo(conexao)
    operacao, demanda = corpo["operacao"], corpo["passageiros"]
    dados = {
        "operacao": {"inicio": str(operacao["inicio"]), "fim": str(operacao["fim"])},
        "passageiros": {"inicio": str(demanda["inicio"]), "fim": str(demanda["fim"])},
        "linhas": list(limites.linhas),
    }
    texto = (
        f"A base tem dados de operação {periodo_br(operacao['inicio'], operacao['fim'])} e de passageiros "
        f"{periodo_br(demanda['inicio'], demanda['fim'])}, para as linhas {', '.join(limites.linhas)}. "
        "Expressões como \"última semana\" contam a partir do último dia com dados."
    )
    return Resultado("sobre_os_dados", dados, texto, tela(
        "Dados disponíveis",
        [
            indicador("Operação", rotulo_periodo(operacao["inicio"], operacao["fim"])),
            indicador("Passageiros", rotulo_periodo(demanda["inicio"], demanda["fim"])),
            indicador("Linhas", len(limites.linhas)),
        ],
    ))


def _resumo(conexao: Connection, inicio, fim) -> dict:
    corpo = indicadores.resumo(inicio, fim, conexao)
    return {**corpo, "inicio": str(corpo["inicio"]), "fim": str(corpo["fim"])}


def _texto_resumo(r: dict) -> str:
    if not r["dias_com_operacao"]:
        return f"Não encontrei registro de operação {periodo_br(r['inicio'], r['fim'])}."
    texto = (
        f"{periodo_br(r['inicio'], r['fim']).capitalize()}, foram realizadas {inteiro(r['viagens_realizadas'])} "
        f"de {inteiro(r['viagens_programadas'])} viagens programadas, um cumprimento de "
        f"{porcentagem(r['cumprimento'], 2)}. A frota rodou {decimal(r['km_total'])} km, dos quais "
        f"{porcentagem(r['parcela_km_improdutivo'])} foram improdutivos."
    )
    if r["dias_com_passageiros"]:
        texto += (
            f" Nos {r['dias_com_passageiros']} dias com dado de passageiros, o sistema transportou "
            f"{inteiro(r['passageiros'])} pessoas"
            + (f", com IPK de {decimal(r['ipk'], 3)} passageiros por km." if r["ipk"] else ".")
        )
    return texto


def resumo_operacao(conexao: Connection, limites: Limites, inicio, fim) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites)
    r = _resumo(conexao, inicio, fim)
    cumprimento = r["cumprimento"]
    itens = [
        indicador("Viagens realizadas", r["viagens_realizadas"]),
        indicador("Viagens programadas", r["viagens_programadas"]),
        indicador("Cumprimento", round(cumprimento * 100, 2) if cumprimento is not None else "sem dado", "%"),
        indicador("Km total", round(r["km_total"], 1), "km"),
    ]
    if r["dias_com_passageiros"]:
        itens.append(indicador("Passageiros", r["passageiros"]))
        if r["ipk"] is not None:
            itens.append(indicador("IPK", r["ipk"], "pass./km"))
    return Resultado("resumo_operacao", r, _texto_resumo(r),
                     tela(f"Resumo da operação · {rotulo_periodo(inicio, fim)}", itens))


def _variacao(atual, anterior) -> float | None:
    if not anterior or atual is None:
        return None
    return round((atual - anterior) / anterior, 4)


def comparar_periodos(conexao: Connection, limites: Limites, inicio_a, fim_a, inicio_b, fim_b) -> Resultado:
    inicio_a, fim_a = validar_periodo(inicio_a, fim_a, limites)
    inicio_b, fim_b = validar_periodo(inicio_b, fim_b, limites)
    a, b = _resumo(conexao, inicio_a, fim_a), _resumo(conexao, inicio_b, fim_b)
    medidas = [
        ("Viagens realizadas", "viagens_realizadas", "dias_com_operacao", inteiro),
        ("Km total", "km_total", "dias_com_operacao", decimal),
        ("Passageiros", "passageiros", "dias_com_passageiros", inteiro),
    ]
    linhas = []
    variacoes = {}
    for nome, chave, dias, formato in medidas:
        media_a, media_b = (a[chave] or 0) / (a[dias] or 1), (b[chave] or 0) / (b[dias] or 1)
        variacoes[chave] = _variacao(media_b, media_a)
        linhas.append([f"{nome} por dia", formato(media_a), formato(media_b), porcentagem(variacoes[chave])])
    linhas.append(["Cumprimento", porcentagem(a["cumprimento"], 2), porcentagem(b["cumprimento"], 2), ""])
    rotulo_a, rotulo_b = rotulo_periodo(inicio_a, fim_a), rotulo_periodo(inicio_b, fim_b)
    texto = (
        f"Comparando {rotulo_a} com {rotulo_b}, pela média diária: viagens realizadas variaram "
        f"{porcentagem(variacoes['viagens_realizadas'])}, a quilometragem {porcentagem(variacoes['km_total'])} "
        f"e os passageiros {porcentagem(variacoes['passageiros'])}. O cumprimento foi de "
        f"{porcentagem(a['cumprimento'], 2)} para {porcentagem(b['cumprimento'], 2)}."
    )
    return Resultado(
        "comparar_periodos",
        {"periodo_a": a, "periodo_b": b, "variacao_media_diaria": variacoes},
        texto,
        tela(f"Comparação · {rotulo_a} × {rotulo_b}", [],
             ["Medida", rotulo_a, rotulo_b, "Variação"], linhas),
    )


def viagens_por_linha(conexao: Connection, limites: Limites, inicio, fim) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites)
    linhas = sorted(indicadores.linhas(inicio, fim, conexao), key=lambda l: -(l["viagens"] or 0))
    if linhas:
        primeira, ultima = linhas[0], linhas[-1]
        texto = (
            f"{periodo_br(inicio, fim).capitalize()}, a linha {primeira['linha']} foi a que mais fez viagens: "
            f"{inteiro(primeira['viagens'])}, em {decimal(primeira['km_total'])} km. A que menos fez foi a "
            f"{ultima['linha']}, com {inteiro(ultima['viagens'])}."
        )
    else:
        texto = f"Não encontrei viagens por linha {periodo_br(inicio, fim)}."
    return Resultado(
        "viagens_por_linha",
        {"inicio": str(inicio), "fim": str(fim), "linhas": linhas},
        texto,
        tela(f"Viagens por linha · {rotulo_periodo(inicio, fim)}",
             [indicador("Linhas com operação", len(linhas))],
             ["Linha", "Viagens", "Km total", "Dias"],
             [[l["linha"], l["viagens"], round(l["km_total"] or 0, 1), l["dias"]] for l in linhas]),
    )


def passageiros_por_dia(conexao: Connection, limites: Limites, inicio, fim) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites)
    dias = indicadores.passageiros_por_dia(inicio, fim, conexao)
    total = sum(d["total"] or 0 for d in dias)
    nao_pagantes = sum(d["nao_pagantes"] or 0 for d in dias)
    catraca = sum(d["catraca"] or 0 for d in dias)
    antecipados = sum(d["antecipados"] or 0 for d in dias)
    parcela = nao_pagantes / total if total else None
    if dias:
        texto = (
            f"{periodo_br(inicio, fim).capitalize()} ({len(dias)} dias com dado), o sistema transportou "
            f"{inteiro(total)} passageiros. Desses, {inteiro(nao_pagantes)} foram não pagantes "
            f"({porcentagem(parcela)}), {inteiro(catraca)} pagaram na catraca e {inteiro(antecipados)} usaram "
            "passagem antecipada. A base só tem passageiros do sistema inteiro, não por linha."
        )
    else:
        texto = (
            f"Não encontrei registro de passageiros {periodo_br(inicio, fim)}. "
            "Os relatórios de passageiros começam depois dos de operação."
        )
    return Resultado(
        "passageiros_por_dia",
        {"inicio": str(inicio), "fim": str(fim), "dias_com_dado": len(dias), "total": total,
         "nao_pagantes": nao_pagantes, "catraca": catraca, "antecipados": antecipados,
         "parcela_nao_pagantes": round(parcela, 4) if parcela is not None else None,
         "por_dia": [{**d, "data": str(d["data"])} for d in dias]},
        texto,
        tela(f"Passageiros · {rotulo_periodo(inicio, fim)}",
             [indicador("Total", total), indicador("Não pagantes", nao_pagantes),
              indicador("Gratuidade", round(100 * parcela, 1) if parcela is not None else "sem dado", "%"),
              indicador("Dias com dado", len(dias))],
             ["Data", "Catraca", "Antecipados", "Não pagantes", "Total"],
             [[data_br(d["data"]), d["catraca"], d["antecipados"], d["nao_pagantes"], d["total"]] for d in dias]),
    )


def partidas_por_faixa_horaria(conexao: Connection, limites: Limites, inicio, fim, linha=None) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites)
    linha = validar_linha(linha, limites)
    t = tabelas.partidas_faixa_horaria if linha else tabelas.resumo_faixa_horaria
    consulta = (
        select(t.c.fx_hor, func.sum(t.c.nr_viagens).label("viagens"),
               func.avg(t.c.nr_veiculos).label("veiculos_medios"))
        .where(t.c.data.between(inicio, fim))
        .group_by(t.c.fx_hor)
        .order_by(t.c.fx_hor)
    )
    if linha:
        consulta = consulta.where(t.c.linha == linha)
    faixas = linhas_da_consulta(conexao, consulta)
    for faixa in faixas:
        faixa["veiculos_medios"] = round(float(faixa["veiculos_medios"] or 0), 1)
    pico = max(faixas, key=lambda f: f["viagens"] or 0) if faixas else None
    alvo = f"Na linha {linha}" if linha else "No sistema"
    if pico:
        texto = (
            f"{alvo}, {periodo_br(inicio, fim)}, a faixa com mais viagens foi a das {pico['fx_hor']:02d}h, "
            f"com {inteiro(pico['viagens'])} viagens e, em média, {decimal(pico['veiculos_medios'])} veículos rodando."
        )
    else:
        texto = f"Não encontrei partidas por faixa horária {periodo_br(inicio, fim)}."
    return Resultado(
        "partidas_por_faixa_horaria",
        {"inicio": str(inicio), "fim": str(fim), "linha": linha, "faixas": faixas, "pico": pico},
        texto,
        tela(f"Viagens por faixa horária ({f'linha {linha}' if linha else 'sistema'}) · {rotulo_periodo(inicio, fim)}",
             [indicador("Faixa de pico", f"{pico['fx_hor']:02d}h" if pico else "sem dado"),
              indicador("Viagens no pico", pico["viagens"] if pico else 0)],
             ["Faixa", "Viagens", "Veículos (média)"],
             [[f"{f['fx_hor']:02d}h", f["viagens"], f["veiculos_medios"]] for f in faixas]),
    )


def viagens_com_problema(conexao: Connection, limites: Limites, inicio, fim, situacao=None) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites)
    if situacao and situacao not in SITUACOES:
        raise ValueError(f"Situação desconhecida. Use: {', '.join(SITUACOES)}.")
    t = tabelas.viagens_excecao
    consulta = (
        select(t.c.situacao, t.c.data, t.c.linha, t.c.inicio_programado, t.c.atendimento)
        .where(t.c.data.between(inicio, fim))
        .order_by(t.c.data, t.c.inicio_programado)
    )
    if situacao:
        consulta = consulta.where(t.c.situacao == situacao)
    viagens = linhas_da_consulta(conexao, consulta)
    por_situacao: dict[str, int] = {}
    por_linha: dict[str, int] = {}
    for v in viagens:
        por_situacao[v["situacao"]] = por_situacao.get(v["situacao"], 0) + 1
        por_linha[v["linha"]] = por_linha.get(v["linha"], 0) + 1
    if viagens:
        partes = ", ".join(f"{n} {SITUACOES[s]}{'s' if n > 1 else ''}" for s, n in sorted(por_situacao.items()))
        linha_mais, ocorrencias = max(por_linha.items(), key=lambda par: par[1])
        texto = (
            f"{periodo_br(inicio, fim).capitalize()}, houve {len(viagens)} viagens com problema: {partes}. "
            f"A linha com mais ocorrências foi a {linha_mais} ({ocorrencias})."
        )
    else:
        texto = f"Não encontrei viagens com problema {periodo_br(inicio, fim)}."
    return Resultado(
        "viagens_com_problema",
        {"inicio": str(inicio), "fim": str(fim), "situacao": situacao, "quantidade": len(viagens),
         "por_situacao": por_situacao, "por_linha": por_linha,
         "exemplos": [{**v, "data": str(v["data"]), "inicio_programado": str(v["inicio_programado"])}
                      for v in viagens[:MAXIMO_DE_EXEMPLOS]]},
        texto,
        tela(f"Viagens com problema · {rotulo_periodo(inicio, fim)}",
             [indicador("Total", len(viagens))]
             + [indicador(SITUACOES[s].capitalize(), n) for s, n in sorted(por_situacao.items())],
             ["Data", "Linha", "Situação", "Horário programado", "Atendimento"],
             [[data_br(v["data"]), v["linha"], SITUACOES[v["situacao"]],
               v["inicio_programado"].strftime("%H:%M") if v["inicio_programado"] else "",
               (v["atendimento"] or "").strip()] for v in viagens]),
    )


def creditos(conexao: Connection, limites: Limites, inicio, fim) -> Resultado:
    inicio, fim = validar_periodo(inicio, fim, limites)
    vendas = indicadores.creditos(inicio, fim, conexao)["vendas"]
    total_vendas = round(sum(v["total_vendas"] or 0 for v in vendas), 2)
    total_uso = round(sum(v["total_utilizacao"] or 0 for v in vendas), 2)
    diferenca = round(total_vendas - total_uso, 2)
    if vendas:
        relacao = "maiores" if diferenca > 0 else "menores" if diferenca < 0 else "iguais"
        texto = (
            f"{periodo_br(inicio, fim).capitalize()}, as vendas de créditos somaram {reais(total_vendas)} e a "
            f"utilização {reais(total_uso)}. As vendas foram {relacao} que a utilização"
            + (f" em {reais(abs(diferenca))}." if diferenca else ".")
        )
    else:
        texto = f"Não encontrei registro de créditos {periodo_br(inicio, fim)}."
    return Resultado(
        "creditos",
        {"inicio": str(inicio), "fim": str(fim), "dias_com_dado": len(vendas), "total_vendas": total_vendas,
         "total_utilizacao": total_uso, "diferenca": diferenca,
         "por_dia": [{**v, "data": str(v["data"])} for v in vendas]},
        texto,
        tela(f"Créditos · {rotulo_periodo(inicio, fim)}",
             [indicador("Vendas", total_vendas, "R$"), indicador("Utilização", total_uso, "R$"),
              indicador("Vendas − utilização", diferenca, "R$")],
             ["Data", "Vendas (R$)", "Utilização (R$)", "Vendas − utilização (R$)"],
             [[data_br(v["data"]), v["total_vendas"], v["total_utilizacao"], v["credito_circulante"]]
              for v in vendas]),
    )

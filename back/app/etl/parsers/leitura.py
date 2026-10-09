"""Leitura dos arquivos HTML do Smart Report.

Abre um arquivo e devolve os relatórios que estão dentro dele, com tudo como texto,
igual ao arquivo. Converter números e datas é trabalho da limpeza, não da leitura.
"""

from dataclasses import dataclass
from pathlib import Path

import pandas as pd
from lxml import html

_MESES = {
    "Janeiro": 1, "Fevereiro": 2, "Março": 3, "Abril": 4, "Maio": 5, "Junho": 6,
    "Julho": 7, "Agosto": 8, "Setembro": 9, "Outubro": 10, "Novembro": 11, "Dezembro": 12,
}


@dataclass
class RelatorioLido:
    titulo: str  
    gerado_em: str  
    mes_referencia: str 
    periodo: str 
    arquivo: str 
    tabela: pd.DataFrame  


def _texto(elemento) -> str:
    """Texto de uma célula, com espaços e quebras de linha reduzidos a um espaço."""
    return " ".join(" ".join(elemento.itertext()).split())


def contexto_do_caminho(caminho: Path) -> tuple[str, str, str]:
    """Tira mês de referência, período e caminho relativo da pasta do arquivo.

    Espera .../<Mês>_<ano>/<Mensal|Quinzenal>/<arquivo>.html
    """
    pasta_mes, pasta_periodo = caminho.parts[-3], caminho.parts[-2]
    nome_mes, _, ano = pasta_mes.partition("_")
    if nome_mes not in _MESES or not ano.isdigit():
        raise ValueError(f"Pasta de mês fora do padrão '<Mês>_<ano>': {pasta_mes}")
    mes_referencia = f"{ano}-{_MESES[nome_mes]:02d}"
    arquivo = f"{pasta_mes}/{pasta_periodo}/{caminho.name}"
    return mes_referencia, pasta_periodo.lower(), arquivo


def _data_de_geracao(cabecalho) -> str:
    """Acha a linha 'Gerado por "Smart Report"' e devolve a célula ao lado."""
    for linha in cabecalho.xpath("//tr"):
        celulas = [_texto(td) for td in linha.xpath("./td")]
        if len(celulas) >= 2 and "Smart Report" in celulas[0]:
            return celulas[1]
    return ""


def ler_arquivo(caminho: Path) -> list[RelatorioLido]:
    """Lê um arquivo do Smart Report e devolve um RelatorioLido por relatório encontrado."""
    mes_referencia, periodo, arquivo = contexto_do_caminho(caminho)

  
    conteudo = caminho.read_text(encoding="cp1252")
    documentos = [
        html.fromstring("<!DOCTYPE" + parte)
        for parte in conteudo.split("<!DOCTYPE")
        if parte.strip()
    ]
    if len(documentos) < 2:
        raise ValueError(f"Arquivo sem relatório depois do cabeçalho: {arquivo}")

    gerado_em = _data_de_geracao(documentos[0])
    relatorios = []
    for documento in documentos[1:]:
        titulos = documento.xpath("//h1")
        if not titulos:
            continue
        titulo = _texto(titulos[0])
        for tabela in documento.xpath("//table"):
            
            colunas = [_texto(th) for th in tabela.xpath(".//th")]
            if not colunas or "SmartDataSource" in colunas[0]:
                continue  
            linhas = [[_texto(td) for td in tr.xpath("./td")] for tr in tabela.xpath(".//tr")]
            linhas = [linha for linha in linhas if linha]
            relatorios.append(
                RelatorioLido(
                    titulo=titulo,
                    gerado_em=gerado_em,
                    mes_referencia=mes_referencia,
                    periodo=periodo,
                    arquivo=arquivo,
                    tabela=pd.DataFrame(linhas, columns=colunas, dtype=str),
                )
            )
    return relatorios
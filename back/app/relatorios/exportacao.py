import csv
import io
import re
from datetime import date, datetime

from fpdf import FPDF
from fpdf.enums import XPos, YPos
from fpdf.fonts import FontFace
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill

from app.formatos import data_br, decimal, inteiro, reais
from app.texto import normalizar

AZUL = (31, 95, 168)
CINZA = (90, 100, 115)
TINTA = (20, 35, 58)

TIPOS = {
    "pdf": "application/pdf",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "csv": "text/csv; charset=utf-8",
}

TROCAS_LATIN1 = {"−": "-", "–": "-", "—": "-", "•": "-", "…": "...", "“": '"', "”": '"', "‘": "'", "’": "'",
                 "→": "->", "×": "x"}


def nome_do_arquivo(relatorio: dict, formato: str) -> str:
    base = re.sub(r"[^a-z0-9]+", "-", normalizar(relatorio["titulo"])).strip("-")
    return f"{base}_{relatorio['inicio']}_{relatorio['fim']}.{formato}"


def _periodo(relatorio: dict) -> str:
    return f"{data_br(relatorio['inicio'])} a {data_br(relatorio['fim'])}"


def _gerado(relatorio: dict) -> str:
    return datetime.fromisoformat(relatorio["gerado_em"]).strftime("%d/%m/%Y %H:%M")


def _valor(indicador: dict) -> str:
    valor, unidade = indicador["valor"], indicador.get("unidade", "")
    if not isinstance(valor, (int, float)) or isinstance(valor, bool):
        return str(valor)
    if unidade == "R$":
        return reais(valor)
    texto = inteiro(valor) if float(valor).is_integer() else decimal(valor, 2)
    if unidade == "%":
        return f"{texto}%"
    return f"{texto} {unidade}".strip()


def _celula(valor) -> str:
    if valor is None:
        return "-"
    if isinstance(valor, bool):
        return "sim" if valor else "não"
    if isinstance(valor, int):
        return inteiro(valor)
    if isinstance(valor, float):
        return decimal(valor, 2)
    return str(valor)


def _latin1(texto) -> str:
    texto = str(texto)
    for de, para in TROCAS_LATIN1.items():
        texto = texto.replace(de, para)
    return texto.encode("latin-1", "replace").decode("latin-1")


class _PDF(FPDF):
    def __init__(self, relatorio: dict):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.relatorio = relatorio
        self.set_auto_page_break(auto=True, margin=16)
        self.set_margins(14, 14, 14)

    def header(self):
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(*AZUL)
        self.cell(0, 5, _latin1(f"{self.relatorio['organizacao']} · {self.relatorio['cidade']}"),
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(*AZUL)
        self.line(14, self.get_y() + 1, 196, self.get_y() + 1)
        self.ln(4)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "", 7)
        self.set_text_color(*CINZA)
        self.cell(0, 5, _latin1(f"Ferret · gerado em {_gerado(self.relatorio)} · página {self.page_no()}/{{nb}}"),
                  align="C")

    def paragrafo(self, texto: str, tamanho: float = 9.5) -> None:
        self.set_font("Helvetica", "", tamanho)
        self.set_text_color(*TINTA)
        self.multi_cell(0, 5, _latin1(texto), new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    def indicadores(self, itens: list[dict]) -> None:
        self.set_font("Helvetica", "", 9)
        with self.table(col_widths=(60, 40), width=100, align="LEFT", first_row_as_headings=False,
                        line_height=5) as tabela:
            for item in itens:
                linha = tabela.row()
                linha.cell(_latin1(item["nome"]))
                linha.cell(_latin1(_valor(item)))

    def tabela_de_dados(self, dados: dict) -> None:
        self.set_font("Helvetica", "", 7.5)
        cabecalho = FontFace(emphasis="BOLD", color=(255, 255, 255), fill_color=AZUL)
        with self.table(line_height=4.2, headings_style=cabecalho, text_align="LEFT") as tabela:
            topo = tabela.row()
            for coluna in dados["colunas"]:
                topo.cell(_latin1(coluna))
            for registro in dados["linhas"]:
                linha = tabela.row()
                for valor in registro:
                    linha.cell(_latin1(_celula(valor)))


def para_pdf(relatorio: dict) -> bytes:
    pdf = _PDF(relatorio)
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 18)
    pdf.set_text_color(*TINTA)
    pdf.cell(0, 10, _latin1(relatorio["titulo"]), new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(*CINZA)
    pdf.cell(0, 6, _latin1(f"Período: {_periodo(relatorio)}"), new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(3)
    pdf.paragrafo(relatorio["resumo"], 10)

    for secao in relatorio["secoes"]:
        if pdf.get_y() > 250:
            pdf.add_page()
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 12)
        pdf.set_text_color(*AZUL)
        pdf.cell(0, 7, _latin1(secao["titulo"]), new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        if secao.get("texto"):
            pdf.paragrafo(secao["texto"])
            pdf.ln(1)
        if secao.get("indicadores"):
            pdf.indicadores(secao["indicadores"])
            pdf.ln(2)
        if secao.get("tabela") and secao["tabela"]["linhas"]:
            pdf.tabela_de_dados(secao["tabela"])
    return bytes(pdf.output())


def _nome_aba(titulo: str, usados: set[str]) -> str:
    nome = re.sub(r"[\[\]:*?/\\]", " ", titulo)[:28].strip() or "Seção"
    final, numero = nome, 2
    while final in usados:
        final, numero = f"{nome[:25]} {numero}", numero + 1
    usados.add(final)
    return final


def _pintar_cabecalho(linha) -> None:
    for celula in linha:
        celula.font = Font(bold=True, color="FFFFFF")
        celula.fill = PatternFill("solid", fgColor="1F5FA8")


def para_xlsx(relatorio: dict) -> bytes:
    livro = Workbook()
    resumo = livro.active
    resumo.title = "Resumo"
    resumo.append([relatorio["titulo"]])
    resumo["A1"].font = Font(bold=True, size=14)
    resumo.append([f"{relatorio['organizacao']} · {relatorio['cidade']}"])
    resumo.append([f"Período: {_periodo(relatorio)}", f"Gerado em {_gerado(relatorio)}"])
    resumo.append([])
    resumo.append([relatorio["resumo"]])
    resumo["A5"].alignment = Alignment(wrap_text=True, vertical="top")
    resumo.merge_cells("A5:D5")
    resumo.row_dimensions[5].height = max(60, 15 * (len(relatorio["resumo"]) // 90 + 1))
    resumo.append([])
    resumo.append(["Seção", "Indicador", "Valor", "Unidade"])
    _pintar_cabecalho(resumo[resumo.max_row])
    for secao in relatorio["secoes"]:
        for item in secao.get("indicadores", []):
            resumo.append([secao["titulo"], item["nome"], item["valor"], item.get("unidade", "")])
    for coluna, largura in zip("ABCD", (38, 38, 18, 12)):
        resumo.column_dimensions[coluna].width = largura

    usados = {"Resumo"}
    for secao in relatorio["secoes"]:
        tabela = secao.get("tabela")
        if not tabela or not tabela["linhas"]:
            continue
        aba = livro.create_sheet(_nome_aba(secao["titulo"], usados))
        aba.append([secao["titulo"]])
        aba["A1"].font = Font(bold=True)
        aba.append(tabela["colunas"])
        _pintar_cabecalho(aba[2])
        for registro in tabela["linhas"]:
            aba.append([v.isoformat() if isinstance(v, (date, datetime)) else v for v in registro])
        for indice, coluna in enumerate(tabela["colunas"], start=1):
            letra = aba.cell(row=2, column=indice).column_letter
            aba.column_dimensions[letra].width = max(12, min(48, len(str(coluna)) + 4))
        aba.freeze_panes = "A3"

    saida = io.BytesIO()
    livro.save(saida)
    return saida.getvalue()


def para_csv(colunas: list[str], linhas: list[list]) -> bytes:
    saida = io.StringIO()
    escritor = csv.writer(saida, delimiter=";", lineterminator="\n")
    escritor.writerow(colunas)
    for linha in linhas:
        escritor.writerow(["" if v is None else v for v in linha])
    return ("﻿" + saida.getvalue()).encode("utf-8")

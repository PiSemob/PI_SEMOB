import io
import zipfile

from openpyxl import load_workbook

from app.relatorios import exportacao

RELATORIO = {
    "modelo": "executivo",
    "titulo": "Relatório Executivo",
    "organizacao": "SEMOB-SCS",
    "cidade": "São Caetano do Sul",
    "inicio": "2026-08-01",
    "fim": "2026-08-31",
    "gerado_em": "2026-11-06T10:00:00",
    "resumo": "Em agosto, o cumprimento foi de 99,84% — com 34.994 viagens “realizadas”.",
    "secoes": [
        {
            "titulo": "Linhas",
            "texto": "A linha 03 liderou.",
            "indicadores": [{"nome": "Cumprimento", "valor": 99.84, "unidade": "%"},
                            {"nome": "Vendas", "valor": 668605.71, "unidade": "R$"}],
            "tabela": {"colunas": ["Linha", "Viagens", "Km"], "linhas": [["03", 5848, 45189.3], ["08", 1676, None]]},
        },
        {"titulo": "Sem tabela", "texto": "Só texto.", "indicadores": [], "tabela": None},
    ],
}


def test_pdf_valido_e_com_acentos():
    conteudo = exportacao.para_pdf(RELATORIO)
    assert conteudo.startswith(b"%PDF")
    assert len(conteudo) > 1500


def test_excel_tem_resumo_e_uma_aba_por_tabela():
    livro = load_workbook(io.BytesIO(exportacao.para_xlsx(RELATORIO)))
    assert livro.sheetnames == ["Resumo", "Linhas"]
    linhas = list(livro["Linhas"].iter_rows(values_only=True))
    assert linhas[1] == ("Linha", "Viagens", "Km")
    assert linhas[2] == ("03", 5848, 45189.3)
    resumo = [c for linha in livro["Resumo"].iter_rows(values_only=True) for c in linha if c]
    assert "Cumprimento" in resumo and 99.84 in resumo


def test_csv_com_bom_ponto_e_virgula_e_vazio_no_lugar_de_none():
    conteudo = exportacao.para_csv(["data", "viagens"], [["2026-08-01", 100], ["2026-08-02", None]])
    texto = conteudo.decode("utf-8")
    assert texto.startswith("﻿")
    assert texto.lstrip("﻿").splitlines() == ["data;viagens", "2026-08-01;100", "2026-08-02;"]


def test_nome_do_arquivo_sem_acento():
    assert exportacao.nome_do_arquivo(RELATORIO, "pdf") == "relatorio-executivo_2026-08-01_2026-08-31.pdf"


def test_xlsx_e_um_zip_do_office():
    with zipfile.ZipFile(io.BytesIO(exportacao.para_xlsx(RELATORIO))) as arquivo:
        assert "xl/workbook.xml" in arquivo.namelist()

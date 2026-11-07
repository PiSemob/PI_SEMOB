from dataclasses import dataclass
from pathlib import Path

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from app.config import PASTA_DOCUMENTOS, PASTA_MODELOS

ARQUIVO_INDICE = PASTA_MODELOS / "indice_documentos.joblib"
EXTENSOES = (".txt", ".md")
TAMANHO_TRECHO = 900


@dataclass
class Trecho:
    documento: str
    texto: str


def dividir(texto: str, tamanho: int = TAMANHO_TRECHO) -> list[str]:
    trechos, atual = [], ""
    for paragrafo in (p.strip() for p in texto.split("\n\n")):
        if not paragrafo:
            continue
        if atual and len(atual) + len(paragrafo) > tamanho:
            trechos.append(atual)
            atual = ""
        while len(paragrafo) > tamanho:
            trechos.append(paragrafo[:tamanho])
            paragrafo = paragrafo[tamanho:]
        atual = f"{atual}\n\n{paragrafo}".strip()
    if atual:
        trechos.append(atual)
    return trechos


def ler_documentos(pasta: Path = PASTA_DOCUMENTOS) -> list[Trecho]:
    if not pasta.exists():
        return []
    trechos = []
    for caminho in sorted(pasta.rglob("*")):
        if caminho.is_file() and caminho.suffix.lower() in EXTENSOES:
            nome = caminho.relative_to(pasta).as_posix()
            texto = caminho.read_text(encoding="utf-8", errors="replace")
            trechos += [Trecho(nome, t) for t in dividir(texto)]
    return trechos


class IndiceDocumentos:
    def __init__(self, trechos: list[Trecho]):
        self.trechos = trechos
        self.vetorizador = TfidfVectorizer(strip_accents="unicode", lowercase=True, ngram_range=(1, 2))
        self.matriz = self.vetorizador.fit_transform([t.texto for t in trechos]) if trechos else None

    def buscar(self, consulta: str, quantos: int = 3, minimo: float = 0.05) -> list[Trecho]:
        if self.matriz is None or not consulta.strip():
            return []
        notas = cosine_similarity(self.vetorizador.transform([consulta]), self.matriz)[0]
        return [self.trechos[i] for i in notas.argsort()[::-1][:quantos] if notas[i] >= minimo]


def construir(pasta: Path = PASTA_DOCUMENTOS) -> IndiceDocumentos:
    return IndiceDocumentos(ler_documentos(pasta))


def salvar(indice: IndiceDocumentos, arquivo: Path = ARQUIVO_INDICE) -> None:
    arquivo.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(indice, arquivo)


def carregar(arquivo: Path = ARQUIVO_INDICE) -> IndiceDocumentos | None:
    return joblib.load(arquivo) if arquivo.exists() else None

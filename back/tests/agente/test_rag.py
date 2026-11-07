from app.db import vetorial


def test_divide_em_trechos_sem_passar_do_tamanho():
    texto = "\n\n".join(["parágrafo " + "x" * 300] * 10)
    trechos = vetorial.dividir(texto, tamanho=900)
    assert len(trechos) > 1
    assert all(len(t) <= 900 for t in trechos)


def test_acha_o_documento_pelo_assunto(tmp_path):
    (tmp_path / "decreto_atrasos.md").write_text(
        "Art. 3º O descumprimento de horário por mais de 15 minutos gera notificação à operadora.",
        encoding="utf-8",
    )
    (tmp_path / "manual_tarifas.txt").write_text(
        "A tarifa de integração é cobrada uma vez a cada duas horas no cartão.", encoding="utf-8"
    )
    (tmp_path / "ignorado.pdf").write_bytes(b"%PDF")
    indice = vetorial.construir(tmp_path)
    assert {t.documento for t in indice.trechos} == {"decreto_atrasos.md", "manual_tarifas.txt"}

    achados = indice.buscar("descumprimento de horário da operadora")
    assert achados[0].documento == "decreto_atrasos.md"


def test_sem_documentos_nao_acha_nada(tmp_path):
    assert vetorial.construir(tmp_path / "nao_existe").buscar("qualquer coisa") == []


def test_indice_salvo_e_carregado(tmp_path):
    (tmp_path / "a.txt").write_text("frota reserva em dias de pico", encoding="utf-8")
    arquivo = tmp_path / "indice.joblib"
    vetorial.salvar(vetorial.construir(tmp_path), arquivo)
    assert vetorial.carregar(arquivo).buscar("frota reserva")[0].documento == "a.txt"

from datetime import date


def inteiro(valor) -> str:
    return f"{round(valor or 0):,}".replace(",", ".")


def decimal(valor, casas: int = 1) -> str:
    texto = f"{(valor or 0):,.{casas}f}"
    return texto.replace(",", "X").replace(".", ",").replace("X", ".")


def porcentagem(fracao, casas: int = 1) -> str:
    return "sem dado" if fracao is None else f"{decimal(fracao * 100, casas)}%"


def reais(valor) -> str:
    return f"R$ {decimal(valor, 2)}"


def para_data(valor) -> date:
    return valor if isinstance(valor, date) else date.fromisoformat(str(valor)[:10])


def data_br(valor) -> str:
    return para_data(valor).strftime("%d/%m/%Y")


def periodo_br(inicio, fim) -> str:
    if para_data(inicio) == para_data(fim):
        return f"em {data_br(inicio)}"
    return f"de {data_br(inicio)} a {data_br(fim)}"


def rotulo_periodo(inicio, fim) -> str:
    if para_data(inicio) == para_data(fim):
        return data_br(inicio)
    return f"{data_br(inicio)} a {data_br(fim)}"

import uuid
from datetime import datetime, timedelta

from pymongo.database import Database

COLECAO = "chat_conversas"
TAMANHO_TITULO = 60
RETENCAO_DIAS = 90
MAXIMO_DE_CONVERSAS = 100


def titulo_de(mensagem: str) -> str:
    texto = " ".join(mensagem.split())
    return texto if len(texto) <= TAMANHO_TITULO else texto[: TAMANHO_TITULO - 1] + "…"


def resumo(documento: dict) -> dict:
    return {
        "id": documento["_id"],
        "titulo": documento["titulo"],
        "atualizada_em": documento["atualizada_em"].isoformat(timespec="seconds"),
    }


def completa(documento: dict) -> dict:
    mensagens = [
        {**m, "em": m["em"].isoformat(timespec="seconds") if isinstance(m.get("em"), datetime) else m.get("em")}
        for m in documento.get("mensagens", [])
    ]
    return {**resumo(documento), "mensagens": mensagens}


def nova_conversa(usuario: str, titulo: str) -> dict:
    agora = datetime.now()
    return {"_id": uuid.uuid4().hex, "usuario": usuario, "titulo": titulo,
            "criada_em": agora, "atualizada_em": agora, "mensagens": []}


class HistoricoMongo:
    def __init__(self, banco: Database):
        self.colecao = banco[COLECAO]

    def listar(self, usuario: str) -> list[dict]:
        cursor = self.colecao.find({"usuario": usuario}, {"mensagens": 0})
        return [resumo(d) for d in cursor.sort("atualizada_em", -1).limit(MAXIMO_DE_CONVERSAS)]

    def obter(self, usuario: str, conversa_id: str) -> dict | None:
        documento = self.colecao.find_one({"_id": conversa_id, "usuario": usuario})
        return completa(documento) if documento else None

    def criar(self, usuario: str, titulo: str) -> dict:
        documento = nova_conversa(usuario, titulo)
        self.colecao.insert_one(documento)
        return completa(documento)

    def acrescentar(self, usuario: str, conversa_id: str, mensagens: list[dict]) -> None:
        self.colecao.update_one(
            {"_id": conversa_id, "usuario": usuario},
            {"$push": {"mensagens": {"$each": mensagens}}, "$set": {"atualizada_em": datetime.now()}},
        )

    def apagar(self, usuario: str, conversa_id: str) -> bool:
        return self.colecao.delete_one({"_id": conversa_id, "usuario": usuario}).deleted_count == 1

    def apagar_antigas(self) -> int:
        limite = datetime.now() - timedelta(days=RETENCAO_DIAS)
        return self.colecao.delete_many({"atualizada_em": {"$lt": limite}}).deleted_count

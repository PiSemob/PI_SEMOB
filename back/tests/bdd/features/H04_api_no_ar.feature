# language: pt
@H04 @RF06
Funcionalidade: API disponível para o app
  Como app Flutter do projeto
  Quero saber se a API do back está no ar
  Para avisar o usuário quando o servidor estiver fora

  Cenário: A rota de saúde responde
    Dado a API do back
    Quando o app chama GET /saude
    Então a resposta tem status 200 e o corpo {"status": "ok"}

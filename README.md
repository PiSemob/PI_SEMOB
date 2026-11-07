# PI SEMOB — Ferret

Plataforma com inteligência artificial para a gestão do transporte público municipal de São Caetano do Sul (SEMOB-SCS).

O sistema lê os relatórios que o Smart Report exporta em HTML, guarda o dado original e uma versão limpa, roda modelos de machine learning sobre a operação e mostra tudo em um app Flutter (o **Ferret**), com um assistente de IA (o **Ferret Jr**).

## Como os dados fluem

```
dados/brutos/*.html          relatórios do Smart Report, como vieram
        │  app/etl/parsers   lê o HTML e identifica o tipo de relatório
        ▼
MongoDB  (camada bruta)       uma coleção por tipo, tudo como texto
        │  app/etl/limpeza   converte, remove duplicatas, sinaliza suspeitos
        ▼
PostgreSQL (camada limpa)     tabelas com chave primária e origem de cada registro
        │
        ├─ app/ml            anomalias (Isolation Forest, DBSCAN) e previsão (Prophet, SARIMAX)
        ▼
API FastAPI  ──────────────▶  app Flutter (front/)
```

- **Nada é apagado:** o que parece errado (duração fora do comum, quilometragem zero, fim antes do início) recebe `suspeito = true` e um `motivo_suspeita`, mas continua na base.
- **A carga pode ser repetida:** quando o mesmo dia aparece no relatório Mensal e no Quinzenal, fica o do arquivo gerado por último. Rodar o `ingerir` duas vezes dá o mesmo resultado que rodar uma.
- **Todo registro sabe de onde veio:** as colunas `arquivo_origem` e `gerado_em` apontam para o HTML original.

## Estrutura

```
.
├── back/                     API, ETL e modelos (Python)
│   ├── app/
│   │   ├── main.py           aplicação FastAPI
│   │   ├── config.py         leitura do .env (único lugar que lê variáveis de ambiente)
│   │   ├── db/               conexões e definição das tabelas do PostgreSQL
│   │   ├── etl/              parsers do HTML, carga bruta e limpeza
│   │   ├── ml/
│   │   │   ├── dados.py      consultas que montam as séries e tabelas dos modelos
│   │   │   ├── fiscalizacao/ Isolation Forest e DBSCAN
│   │   │   └── planejamento/ Prophet, SARIMAX e a escolha entre eles
│   │   ├── api/              rotas da API: login, indicadores, anomalias, previsões, chat,
│   │   │                     relatórios, configurações e notificações
│   │   ├── agente/           assistente Ferret Jr: segurança, intenção, ferramentas, RAG e histórico
│   │   ├── relatorios/       montagem dos 4 relatórios e exportação em PDF, Excel e CSV
│   │   ├── autenticacao.py   usuários, senhas, sessões e recuperação de senha
│   │   ├── configuracoes.py  configurações da plataforma (salvas no PostgreSQL)
│   │   └── correio.py        envio de e-mail (ou arquivo .eml, sem SMTP)
│   ├── scripts/              criar_tabelas, ingerir, treinar, exportar_painel, criar_usuario,
│   │                         enviar_relatorio_diario, indexar_documentos
│   └── tests/                suíte de testes (ver "Testes")
├── front/                    app Flutter (ver front/README.md)
├── dados/brutos/             relatórios HTML do Smart Report
├── dados/documentos/         (opcional) decretos e manuais em .txt/.md para o RAG
├── docker-compose.yml        MongoDB 7 e PostgreSQL 16 (TimescaleDB)
└── .env.example              modelo do arquivo .env
```

Os relatórios ficam em `dados/brutos/<Mês>_<ano>/<Mensal|Quinzenal>/`. O mês de referência e o período são lidos do nome das pastas, então esse padrão precisa ser mantido. A base atual tem 44 arquivos, de 01/07/2026 a 14/09/2026.

## Como rodar

### Pré-requisitos

- Python 3.11 ou mais novo
- Docker Desktop
- Flutter 3.6 ou mais novo (só para o app)
- Android Studio (só para gerar o app de Android)

### 1. Configuração

Na raiz do repositório, copie o modelo e troque a senha:

```powershell
Copy-Item .env.example .env
```

O `.env` nunca vai para o Git.

### 2. Bancos

Com o Docker Desktop aberto, na raiz:

```powershell
docker compose up -d
```

### 3. Back

De dentro de `back/`:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
```

Depois, para criar as tabelas, carregar os relatórios e comparar os modelos de previsão:

```powershell
python -m scripts.criar_tabelas
python -m scripts.ingerir
python -m scripts.treinar
```

O app pede login. Cadastre o primeiro administrador pelo terminal (a senha é pedida na hora, com no mínimo 8 caracteres):

```powershell
python -m scripts.criar_usuario gestor@semob.sp.gov.br "Nome da Pessoa" --admin
```

Os outros funcionários são convidados por um administrador na tela **Usuários** do app: ele informa o nome e o e-mail, e a pessoa recebe um link (válido por 72 horas) para criar a própria senha. Todo usuário vê a aplicação inteira; só administradores abrem a tela Usuários.

E para subir a API:

```powershell
uvicorn app.main:app --reload
```

A rota `GET /saude` responde `{"status": "ok"}`, e a documentação interativa fica em <http://localhost:8000/docs>.

> **Prophet no Windows em português:** com o modo UTF-8 do Python ligado (`PYTHONUTF8=1`) e a pasta do projeto com acento (como "Instituto Mauá" ou "Área de Trabalho"), o Prophet falha com `'Prophet' object has no attribute 'stan_backend'` (por baixo, um `UnicodeDecodeError` ao ler a resposta do `where.exe`, que vem em português). A solução é **desligar** o modo UTF-8: `[Environment]::SetEnvironmentVariable("PYTHONUTF8", $null, "User")` no PowerShell e reabrir o terminal. Enquanto isso não for feito, a API usa o SARIMAX nas séries em que o Prophet foi escolhido (a resposta informa o modelo usado), mas o `scripts.treinar` não roda.

#### Opcional: e-mail

Tudo funciona sem essas variáveis. Com elas no `.env`:

| Variável | O que muda |
|---|---|
| `SMTP_HOST`, `SMTP_PORTA`, `SMTP_USUARIO`, `SMTP_SENHA`, `SMTP_REMETENTE` | O link de recuperação de senha e os relatórios automáticos são enviados por e-mail. Sem SMTP, cada e-mail é gravado em `back/emails/` (fora do Git) e o caminho aparece no terminal da API. |
| `FRONT_URL` (padrão `http://localhost:5555`) | Endereço do app usado no link de recuperação de senha. |

#### Ferret Jr: o que ele faz e o que não faz

Cada mensagem passa, nesta ordem, por:

1. **Limpeza da entrada** (`app/agente/seguranca.py`): tira caracteres de controle e invisíveis e corta em 1.000 caracteres.
2. **Guia do aplicativo** (`app/agente/ajuda.py`): dúvidas de uso ("como exporto um relatório?", "onde vejo as previsões?") recebem a resposta pronta, sem consultar dados.
3. **Bloqueios**: tentativas de mudar as regras do assistente ("ignore suas instruções", "mostre o prompt"), comandos SQL, pedidos de senhas, chaves, usuários ou conversas de outras pessoas, e pedidos para alterar ou apagar dados são recusados antes de qualquer consulta.
4. **Consulta**: `app/agente/intencao.py` classifica a pergunta e `app/agente/interpretacao.py` tira da frase o período, a linha e o que comparar. Com isso, o Ferret Jr escolhe a ferramenta (`app/agente/tools.py`), que lê os dados tratados ou roda o modelo de ML (Isolation Forest, DBSCAN, Prophet ou SARIMAX). O Ferret Jr não usa IA generativa: o texto da resposta é montado a partir dos números que a ferramenta devolve. Toda ferramenta confere os argumentos: só aceita parâmetros conhecidos, datas dentro da base, linhas que existem e períodos de até 120 dias (Isolation Forest) ou 31 dias (DBSCAN).

Outros limites: 10 perguntas por minuto e 300 por dia por pessoa (resposta 429), histórico guardado por 90 dias e resposta sem Markdown, com até 3.000 caracteres. As ferramentas só leem dados: nenhuma escreve no banco.

#### Opcional: relatório diário por e-mail e documentos para o RAG

- Com "Relatórios automáticos" ligado em Configurações, `python -m scripts.enviar_relatorio_diario` envia o Relatório Executivo dos últimos 7 dias em PDF. Para rodar todo dia, agende esse comando no Agendador de Tarefas do Windows.
- Decretos e manuais em `.txt` ou `.md` dentro de `dados/documentos/` são indexados por `python -m scripts.indexar_documentos`. O Ferret Jr passa a citá-los quando encontra uma anomalia.

### 4. Front

De dentro de `front/`:

```powershell
flutter pub get
flutter run -d chrome --web-port 5555 --dart-define=API_URL=http://localhost:8000
```

Entre com um usuário criado pelo `scripts.criar_usuario`. Para apresentar o app sem o back (qualquer e-mail e senha entram, o Ferret Jr e os relatórios não funcionam), use `--dart-define=MODO_DEMO=true`.

O app mostra os dados reais de `dados/brutos`, a partir de `front/assets/dados/painel.json`. Quando entrarem relatórios novos, gere o arquivo de novo de dentro de `back/` (usa o mesmo ETL, sem Docker):

```powershell
python -m scripts.exportar_painel
```

O login, as previsões, as anomalias, o Ferret Jr, os relatórios, as configurações e as notificações vêm da API (passo 3). Sem ela, não dá para entrar no app (a não ser no modo demonstração), e o cabeçalho avisa quando ela cai durante o uso. Os detalhes estão em [front/README.md](front/README.md#api-previsões-e-anomalias).

O mesmo código também gera o app de celular (Android e iOS). Os passos estão em [front/README.md](front/README.md#app-no-celular).

## Banco de dados

### Camada bruta (MongoDB)

Uma coleção por tipo de relatório. Cada documento é uma linha do relatório, com os metadados `tipo`, `periodo`, `mes_referencia`, `arquivo_origem` e `gerado_em`, e o conteúdo original em `dados`.

### Camada limpa (PostgreSQL)

| Tabela | Uma linha por | Origem |
|---|---|---|
| `viagens` | viagem realizada | Viagens |
| `viagens_improdutivas` | veículo e dia (km improdutivo) | Viagens |
| `viagens_excecao` | viagem não iniciada, não realizada ou não terminada | Viag_Ninic, Viag_NRealiz, Viag_NTerm |
| `resumo_geral` | dia | Resumo Geral |
| `resumo_linha` | linha e dia | Resumo por Linha |
| `partidas_faixa_horaria` | linha, dia e faixa horária | Partidas por Faixa Horária |
| `resumo_faixa_horaria` | dia e faixa horária | Resumo por Faixa Horária |
| `fcv` | dia | Fator de Cumprimento de Viagem |
| `passageiros` | dia | Passageiros do Sistema |
| `saldos` | dia e série | Saldo de créditos do sistema |
| `vendas` | dia | Venda x Utilização |

Todas têm as colunas de controle `suspeito`, `motivo_suspeita`, `arquivo_origem` e `gerado_em`.

## Modelos de machine learning

| Modelo | Arquivo | Pergunta que responde |
|---|---|---|
| Isolation Forest | `app/ml/fiscalizacao/isolation_forest.py` | Quais dias de quais linhas fugiram do próprio padrão? |
| DBSCAN | `app/ml/fiscalizacao/dbscan.py` | Dentro de uma linha, quais viagens não se parecem com nenhuma outra? |
| Prophet | `app/ml/planejamento/previsao_prophet.py` | Quanto esperar nos próximos dias? |
| SARIMAX | `app/ml/planejamento/previsao_sarimax.py` | Quanto esperar nos próximos dias? |

- **Anomalias:** os dois modelos apontam o que é estatisticamente atípico. Quem decide se é irregularidade é a SEMOB.
- **Previsão:** as séries são passageiros do sistema e viagens e km do sistema e de cada linha. O `scripts/treinar.py` compara os dois modelos nos últimos 14 dias de cada série e grava em `back/modelos/escolhas.json` qual usar. O `app/ml/planejamento/previsao.py` lê essa escolha. Sem o arquivo, usa o Prophet.
- **Feriados:** entram os nacionais, os do estado de São Paulo e os municipais da lista `FERIADOS_MUNICIPAIS` em `app/ml/planejamento/avaliacao.py`.
- **Modelos não são salvos:** cada treino leva cerca de um segundo, então os modelos são treinados na hora do pedido, sempre com os dados mais recentes. O que fica salvo é só a escolha do modelo por série. A pasta `back/modelos/` fica fora do Git.

## API

O app nunca fala com o banco: ele chama uma rota e recebe JSON. Com a API no ar (`uvicorn app.main:app --reload`), a página <http://localhost:8000/docs> lista todas as rotas e deixa chamar cada uma pelo botão "Try it out".

| Rota | Parâmetros | Devolve |
|---|---|---|
| `GET /saude` | — | `{"status": "ok"}` |
| `GET /indicadores/periodo` | — | Primeiro e último dia com dados de operação e de passageiros |
| `GET /indicadores/resumo` | `inicio`, `fim` | Viagens programadas e realizadas, cumprimento, km, passageiros e IPK do período |
| `GET /indicadores/diario` | `inicio`, `fim` | Uma linha por dia, com viagens, km, veículos e passageiros |
| `GET /indicadores/linhas` | `inicio`, `fim` | Viagens e km de cada linha |
| `GET /indicadores/passageiros` | `inicio`, `fim` | Catraca, antecipados, não pagantes e total, por dia |
| `GET /indicadores/creditos` | `inicio`, `fim` | Vendas e utilização de créditos por dia, e saldos por série |
| `GET /anomalias` | `modelo`, `inicio`, `fim`, `linha` | Dias atípicos (`isolation_forest`) ou viagens atípicas de uma linha (`dbscan`, exige `linha`) |
| `GET /previsoes` | `alvo`, `linha`, `dias` | Previsão de `passageiros`, `viagens` ou `km` de 1 a 14 dias (7 por padrão), com intervalo e o erro na validação |
| `POST /auth/login` | `email`, `senha` | Token da sessão e o usuário |
| `GET /auth/eu` | — | Quem está logado (com o token) |
| `POST /auth/sair` | — | Encerra a sessão |
| `POST /auth/recuperar-senha` | `email` | 202 sempre; manda o link por e-mail se o e-mail existir |
| `POST /auth/redefinir-senha` | `token`, `senha` | 204, ou 400 quando o link é inválido ou expirou; serve também para o convite |
| `GET /usuarios` | — | Usuários cadastrados, com perfil e convite pendente (só administrador) |
| `POST /usuarios` | `email`, `nome`, `admin` | Cadastra e manda o convite por e-mail (só administrador) |
| `POST /usuarios/{id}/convite` | — | Reenvia o convite e invalida o link anterior (só administrador) |
| `PUT /usuarios/{id}` | `admin` | Dá ou tira o perfil de administrador (só administrador) |
| `DELETE /usuarios/{id}` | — | Remove o acesso e encerra as sessões (só administrador) |
| `POST /chat` | `mensagem`, `conversa_id` | Resposta do Ferret Jr: texto, decisão (opção, ferramentas) e os dados da tela; 429 acima do limite de perguntas |
| `GET /chat/conversas` | — | Conversas da pessoa logada |
| `GET` e `DELETE /chat/conversas/{id}` | — | Uma conversa com as mensagens / apaga |
| `POST /relatorios/gerar` | `modelo`, `inicio`, `fim` | Relatório `executivo`, `operacional`, `financeiro` ou `prestacao_contas` |
| `POST /relatorios/exportar` | `modelo`, `inicio`, `fim`, `formato`, `relatorio` | Arquivo `pdf`, `xlsx` ou `csv` |
| `GET` e `PUT /configuracoes` | campos a mudar | Organização, cidade, alertas de anomalia e relatório diário por e-mail |
| `GET /notificacoes` | — | Dias atípicos e viagens não realizadas dos últimos 7 dias com dados |

As rotas de indicadores, anomalias e previsões são abertas (o app de celular as usa sem login). As de chat, relatórios, configurações e notificações exigem `Authorization: Bearer <token>`.

- **Datas** vão e voltam no formato `2026-08-01`.
- **Números** chegam sempre como número no JSON, inclusive quilometragem e dinheiro.
- **Passageiros** só existem para o sistema inteiro. A base não tem passageiros por linha.
- **IPK** (passageiros por quilômetro) usa só os dias que têm passageiros e quilometragem, porque os relatórios de passageiros começam depois dos de operação.

Exemplo:

```
GET /previsoes?alvo=viagens&linha=04&dias=3
```

```json
{
  "serie": "viagens",
  "linha": "04",
  "modelo": "sarimax",
  "erro_na_validacao": {"mae": 2.2, "mape": 2.8},
  "previsao": [
    {"data": "2026-09-15", "previsto": 121.0, "minimo": 113.8, "maximo": 128.2}
  ]
}
```

**Erros:**

| Código | Quando | Corpo |
|---|---|---|
| 400 | Pedido que os dados não atendem: início depois do fim, passageiros por linha, DBSCAN sem linha, linha com poucos dias | `{"detail": "<mensagem para mostrar na tela>"}` |
| 401 | Sem login, e-mail ou senha errados, ou sessão expirada | `{"detail": "<mensagem para mostrar na tela>"}` |
| 422 | Parâmetro faltando ou em formato errado | Lista de erros gerada pelo FastAPI |

**CORS:** a API aceita chamadas de `localhost` e `127.0.0.1` em qualquer porta, que é onde o Flutter Web roda. Outros endereços são bloqueados pelo navegador.

## Testes

### Back

De dentro de `back/`:

```powershell
pytest
```

Cada teste recebe uma marca conforme a pasta em que está, e dá para rodar só uma camada:

| Marca | Pasta | Precisa do Docker |
|---|---|---|
| `unidade` | `tests/etl`, `tests/ml`, `tests/api`, `tests/agente`, `tests/relatorios`, `tests/test_saude.py` | não |
| `integracao` | `tests/integracao` | sim |
| `sistema` | `tests/sistema` | sim |
| `aceitacao` | `tests/aceitacao` | sim |
| `regressao` | `tests/regressao` | não |
| `bdd` | `tests/bdd` | sim, menos a H04 |

```powershell
pytest -m unidade
pytest -m "not sistema"
pytest -m H02          # uma história de usuário
```

Os testes que usam banco criam bancos próprios (`semob_teste...`) e nunca tocam no banco de trabalho `semob`. Sem o Docker, esses testes são pulados. No CI, eles falham.

### Front

De dentro de `front/`:

```powershell
flutter test
```

### Integração contínua

A cada push na `main` e em todo pull request, o GitHub Actions (`.github/workflows/testes.yml`) sobe o MongoDB e o PostgreSQL, roda a suíte do back e publica os relatórios de testes e de cobertura como artefato.

## Commits

As mensagens seguem o padrão `tipo(escopo): descrição`, em português, com o verbo no presente: `feat(ml): adiciona previsão com Prophet`.

| O que foi feito | Tipo |
|---|---|
| Funcionalidade, tela, endpoint ou modelo novo; mudança no que o sistema faz | `feat` |
| Remoção de uma funcionalidade que alguém usava | `feat!` |
| Correção de erro | `fix` |
| Documentação | `docs` |
| Teste | `test` |
| Dependência nova ou atualização de versão | `build` |
| Configuração, dados brutos, arquivo que não é código | `chore` |
| Organização do código sem mudar o resultado, código morto, mover arquivo de código | `refactor` |
| Desempenho | `perf` |
| Só formatação | `style` |
| Desfazer um commit | `revert` |
| Pipeline do GitHub Actions | `ci` |

Na hora do `git add`, adicione os arquivos pelo nome, sem `git add .`.

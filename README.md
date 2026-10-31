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
│   │   ├── api/              rotas da API: indicadores, anomalias e previsões
│   │   └── agente/           assistente Ferret Jr (em construção)
│   ├── scripts/              criar_tabelas, ingerir, treinar, exportar_painel (dados do app)
│   └── tests/                suíte de testes (ver "Testes")
├── front/                    app Flutter (ver front/README.md)
├── dados/brutos/             relatórios HTML do Smart Report
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

E para subir a API:

```powershell
uvicorn app.main:app --reload
```

A rota `GET /saude` responde `{"status": "ok"}`, e a documentação interativa fica em <http://localhost:8000/docs>.

> **Pasta com acento no Windows:** se o caminho do projeto tiver acento (como "Área de Trabalho"), o Prophet falha ao carregar com `'Prophet' object has no attribute 'stan_backend'`. Para resolver, ligue o modo UTF-8 do Python com `setx PYTHONUTF8 1` e reabra o terminal.

### 4. Front

De dentro de `front/`:

```powershell
flutter pub get
flutter run -d chrome
```

O app mostra os dados reais de `dados/brutos`, a partir de `front/assets/dados/painel.json`. Quando entrarem relatórios novos, gere o arquivo de novo de dentro de `back/` (usa o mesmo ETL, sem Docker):

```powershell
python -m scripts.exportar_painel
```

As previsões e as anomalias vêm da API. Com ela no ar (passo 3), rode o app apontando para ela:

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

Sem a API, o app abre normalmente e avisa no cabeçalho que ela está fora do ar. Os detalhes estão em [front/README.md](front/README.md#api-previsões-e-anomalias).

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
| `unidade` | `tests/etl`, `tests/ml`, `tests/api`, `tests/test_saude.py` | não |
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

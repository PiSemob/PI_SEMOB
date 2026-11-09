# Ferret 

Plataforma com IA para gestão do transporte público municipal (SEMOB-SCS).

## Identidade visual

Todos os tokens ficam em [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart):

| Token | Valor | Uso |
|---|---|---|
| `primary` / `primaryHover` | `#1F5FA8` / `#184D8A` | ação principal (botões, links, seleção) |
| `accent` / `accentSoft` | `#3D7CC9` / `#E3EDF8` | destaque e estados "ok" (em rota, conectado) |
| `sidebar` / `sidebarActive` | `#EDF3FA` / `#D6E4F3` | azul-claro da navegação e item atual |
| `ink` | `#14233A` | textos principais e tooltips |
| `background` / `surface` / `border` | `#F5F8FC` / `#FFFFFF` / `#D9E2EC` | superfícies planas e filetes |
| `AppSpacing` | 4 / 8 / 16 / 24 / 32 | espaçamento; raios 8 (controles) / 12 (painéis) |
| `AppTextStyles` | display, title, section, metric, body, label, caption, overline | IBM Plex Sans na interface; IBM Plex Mono nos números |

Elementos de marca compartilhados em [lib/shared/widgets/app_widgets.dart](lib/shared/widgets/app_widgets.dart):
`AppLogo` e `FundoMarca` (fundo em degradê azul-claro do login).

O mapa do município fica em [lib/shared/widgets/mapa_municipio.dart](lib/shared/widgets/mapa_municipio.dart) e lê os GeoJSON de `assets/mapas/` (dados do OpenStreetMap; veja o `LEIA-ME.txt` da pasta). Ele aparece inclinado, em 3D, e mostra o fluxo de viagens: um arco por linha, da Estação São Caetano ao bairro atendido, mais grosso quanto mais viagens. Está no login, na Visão geral e em Operação da Frota.

## Telas

Quatro telas e o assistente. As telas que o stakeholder pediu continuam, como abas com o mesmo nome:

| Menu | Rota | Abas |
|---|---|---|
| Visão geral | `/dashboard` | — (resumo, mapa de fluxos, "Precisa de atenção") |
| Operação | `/operacao` | Demanda · Operação da Frota · Quilometragem |
| Financeiro | `/receita` | Receita · Créditos em Circulação |
| Dados e relatórios | `/dados` | Central de Documentos · Integrações de Dados · Relatórios |
| Ferret Jr | `/assistente` | — |

Configurações abre pela engrenagem ao lado do usuário. Os endereços antigos (`/demanda`, `/frota`, `/creditos` etc.) redirecionam para a aba certa.

### Login e recuperação de senha

O login fala com a API (`POST /auth/login`). O primeiro administrador é criado no back com `python -m scripts.criar_usuario ... --admin`; os outros funcionários são convidados na tela **Usuários** (`/usuarios`), que só aparece no menu e só abre para administradores. O convite chega por e-mail com um link para `/#/criar-senha?token=...`, a mesma tela da redefinição com textos de boas-vindas. O token fica guardado no aparelho (`shared_preferences`), então recarregar a página não desloga; ao abrir, o app confere com `GET /auth/eu` se o token ainda vale. Sem login, qualquer endereço leva a `/login` (proteção em `protegerRota`, em [lib/core/router/app_router.dart](lib/core/router/app_router.dart)). Se a API responder 401 no meio do uso, a sessão é encerrada e o login avisa que ela expirou.

O "Esqueci minha senha" abre `/recuperar-senha`, já com o e-mail digitado, e chama `POST /auth/recuperar-senha`. A pessoa recebe por e-mail um link para `/#/redefinir-senha?token=...` (válido por 60 minutos e uma vez só), onde cria a senha nova com no mínimo 8 caracteres (`POST /auth/redefinir-senha`). Sem SMTP configurado no back, o e-mail é gravado em `back/emails/`.

As telas falam só com a interface `ServicoAutenticacao`, em [lib/core/autenticacao/servico_autenticacao.dart](lib/core/autenticacao/servico_autenticacao.dart). A versão `ServicoAutenticacaoApi` é a padrão; a `ServicoAutenticacaoDemo` (qualquer e-mail e senha entram, nenhum e-mail sai) só é usada com `--dart-define=MODO_DEMO=true`.

### Ferret Jr, relatórios, configurações e notificações

| Onde | O que faz | Rotas |
|---|---|---|
| Ferret Jr | Envia a pergunta, mostra a resposta com os números em tabela, guarda as conversas no back (histórico na lateral, com opção de apagar) | `POST /chat`, `GET/DELETE /chat/conversas` |
| Dados e relatórios › Relatórios | "Gerar relatório" monta o relatório do período escolhido; PDF, Excel e CSV baixam o arquivo (no navegador, como download; no celular ou computador, na pasta de downloads) | `POST /relatorios/gerar`, `POST /relatorios/exportar` |
| Botão "Exportar" do cabeçalho | Leva para a aba Relatórios | — |
| Configurações | Carrega e salva no back; vale para todos os usuários | `GET/PUT /configuracoes` |
| Sino do cabeçalho | Dias atípicos e viagens não realizadas dos últimos 7 dias com dados; o número some depois de aberto | `GET /notificacoes` |

As Configurações têm só o que é da operação: nome da organização e cidade (cabeçalho dos relatórios), alertas de anomalia e o envio diário do Relatório Executivo por e-mail. O app confere a API e as notificações a cada 60 segundos.

## Dados

As telas mostram só dados reais, lidos de `assets/dados/painel.json`. Esse arquivo é gerado pelo back a partir dos relatórios em `dados/brutos`, com o mesmo ETL que alimenta o banco (não precisa de Docker):

```powershell
cd back
python -m scripts.exportar_painel
```

Rode de novo sempre que entrarem relatórios novos. Os períodos ("Últimos 30d" etc.) contam a partir do último dia com dados, não de hoje.

## API (previsões e anomalias)

Os números das telas vêm do `painel.json`. Os resultados dos modelos de machine learning vêm da API do back, porque são calculados na hora:

| Onde aparece | O que mostra | Rota |
|---|---|---|
| Cabeçalho | Se a API está no ar (toque para verificar de novo) | `GET /saude` |
| Operação › Demanda | Previsão de passageiros do sistema nos próximos 7 dias | `GET /previsoes?alvo=passageiros` |
| Operação › Quilometragem | Previsão de viagens e de km do sistema ou da linha escolhida | `GET /previsoes?alvo=viagens` e `alvo=km` |
| Operação › Operação da Frota | Dias atípicos de cada linha (Isolation Forest) e, com uma linha escolhida, as viagens atípicas dela (DBSCAN) | `GET /anomalias` |

As anomalias são pedidas para a base inteira, uma vez só, e a tela mostra as que caem no período escolhido. As previsões começam no dia seguinte ao último dado e não mudam com o filtro de período.

Sem a API, o app abre normalmente: o cabeçalho mostra "API fora do ar" e cada cartão de previsão ou anomalia mostra o motivo e um botão "Tentar de novo".

O código fica em [lib/core/api/api_client.dart](lib/core/api/api_client.dart), que usa o `dio`. Nos testes, troque o `apiClientProvider` por uma classe falsa (exemplos em `test/widget/previsao_*_test.dart`).

### Rodar com a API

Em um terminal, suba os bancos e a API (ver o [README da raiz](../README.md#como-rodar)):

```powershell
cd back
uvicorn app.main:app --reload
```

Em outro, de dentro de `front/`:

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

Sem o `--dart-define`, o app usa `http://localhost:8000`.

| Onde o app roda | `API_URL` |
|---|---|
| Navegador (Flutter Web) | `http://localhost:8000` |
| Emulador Android | `http://10.0.2.2:8000` |
| Celular na mesma rede | `http://<IP do computador>:8000`, com a API iniciada com `--host 0.0.0.0` |

A API só aceita chamadas do navegador vindas de `localhost` e `127.0.0.1` (CORS). No Android 9 ou mais novo e no iOS, o sistema bloqueia endereços `http://` por padrão, então no emulador e no celular as previsões e anomalias ficam indisponíveis até a API ter HTTPS ou o app liberar HTTP para a rede local.

## Como rodar

```bash
flutter pub get
flutter run -d chrome     # ou -d macos / dispositivo
flutter test
dart analyze lib test
```

> **Pasta com acento:** se o caminho do projeto tiver acento (como "Área de Trabalho"), o `flutter analyze` trava com `FormatException: Unexpected end of input`. Use o `dart analyze lib test`, que funciona, ou rode de uma pasta sem acento.

## App no celular

O mesmo código gera o app de Android (pasta `android/`) e de iOS (pasta `ios/`). O app se chama **Ferret** e o identificador é `br.edu.maua.ferret`. Os dados e o mapa vão junto com o app, então ele funciona sem internet. Só as previsões e anomalias precisam da API (ver "Rodar com a API").

### Android

1. Instale o [Android Studio](https://developer.android.com/studio) e, na primeira abertura, deixe ele baixar o Android SDK.
2. Aceite as licenças:
   ```powershell
   flutter doctor --android-licenses
   ```
3. Ligue o celular no USB com a depuração USB ativada (ou abra um emulador pelo Android Studio) e rode:
   ```powershell
   flutter devices
   flutter run
   ```

Para gerar o arquivo de instalação:

```powershell
flutter build apk --release
```

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`. Ele é assinado com a chave de depuração, então serve para instalar e testar, não para publicar na Play Store.

### iOS

Só compila em um Mac com Xcode: conecte o iPhone e rode `flutter run`.

### Ícone

O ícone é a mesma marca que o app desenha enquanto não há logo (o "F" branco com a barra laranja). Os arquivos ficam em `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/` e `web/icons/`.

## Estrutura

```
android/                        # app Android (gerado pelo Flutter)
ios/                            # app iOS (gerado pelo Flutter)
web/                            # versão web e ícones do PWA
assets/
  dados/painel.json             # dados reais, gerados pelo back
  mapas/                        # GeoJSON do município, bairros e vias (OSM)
lib/
  main.dart
  core/
    api/api_client.dart         # cliente HTTP da API (dio), apiClientProvider e apiNoArProvider
    autenticacao/               # sessão (token guardado) e ServicoAutenticacao (API ou demonstração)
    download/                   # salvar arquivo exportado (web: download; celular/computador: pasta)
    router/app_router.dart      # GoRouter + ShellRoute + redirecionamentos
    theme/app_theme.dart        # AppColors, AppSpacing, AppTextStyles, AppTheme
  shared/
    painel.dart                 # modelo dos dados reais e painelProvider
    previsao.dart               # modelo da previsão e previsaoProvider (API)
    anomalias.dart              # dias e viagens atípicos e seus providers (API)
    dados_exemplo.dart          # PontoSerie, modelos de relatório, sugestões do Ferret Jr
    formatters.dart             # número, moeda, data, percentual
    providers.dart              # período e linha escolhida
    configuracoes.dart          # modelo das configurações
    notificacoes.dart           # avisos do sino e notificacoesProvider (API)
    widgets/
      app_shell.dart            # menu, header e PaginaConteudo
      app_widgets.dart          # AppCard, AppButton, AppTextField, TagFiltro...
      abas_pagina.dart          # abas ligadas ao ?aba= da rota
      faixa_indicadores.dart    # indicadores num card só, com mini-tendência
      barra_composicao.dart     # composição de um total numa barra de 100%
      mapa_calor.dart           # grade de cores (faixa horária × dia)
      mapa_municipio.dart       # mapa 3D com fluxos
      tabela_ordenavel.dart     # tabela que ordena pela coluna
      cartao_previsao.dart      # cartão de previsão com gráfico, faixa e erro do modelo
      charts.dart               # linha, barras e barras horizontais
      filtro_periodo_bar.dart   # filtro de período compartilhado
      cartao_dados.dart         # indicadores e tabela de uma resposta do Ferret Jr ou seção de relatório
      sino_notificacoes.dart    # sino do cabeçalho e atualização a cada 60 s
      secoes.dart               # seções de formulário usadas em Configurações e Usuários
  features/
    login/                      # login, esqueci minha senha, senha nova e convite
    dashboard/ operacao/ financeiro/ dados/
    assistente/ relatorios/ configuracoes/
    usuarios/                   # convite, perfil e remoção de usuários (só administrador)
test/
  apoio/painel_teste.dart       # painel pequeno e fixo para os testes
  apoio/api_falsa.dart          # API e serviço de login falsos para os testes
  unit/  widget/
```

## Responsividade

- `< 700px` — mobile: 1 coluna, Drawer de navegação com a marca
- `700–1099px` — tablet: 2 colunas
- `>= 900px` — sidebar fixa de 252px + header
- `>= 1100px` — desktop: 4 colunas

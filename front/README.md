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
`AppLogo`, `LogoScs` e `FundoMarca` (fundo em degradê azul-claro do login).

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

### Recuperação de senha

O "Esqueci minha senha" do login abre `/recuperar-senha`, já com o e-mail digitado. A pessoa recebe por e-mail um link para `/redefinir-senha?token=...`, onde cria a senha nova (mínimo de 8 caracteres).

As telas falam só com a interface `ServicoAutenticacao`, em [lib/core/autenticacao/servico_autenticacao.dart](lib/core/autenticacao/servico_autenticacao.dart). Por enquanto ela usa a versão de demonstração, que não envia e-mail e mostra um botão no lugar do link. Para ligar no back:

1. Criar as rotas em `back/app/api/autenticacao.py`:
   - `POST /auth/recuperar-senha` com `{"email": "..."}`: responde 202 sempre, exista ou não o e-mail, para não revelar quem tem cadastro;
   - `POST /auth/redefinir-senha` com `{"token": "...", "senha": "..."}`: responde 204, ou 400 com `{"detail": "..."}` quando o link é inválido ou expirou.
2. No front, criar uma classe que implementa `ServicoAutenticacao` chamando essas rotas e lançando `ErroAutenticacao` com o `detail` em caso de erro.
3. Trocar o `servicoAutenticacaoProvider` para essa classe. As telas não mudam.

## Dados

As telas mostram só dados reais, lidos de `assets/dados/painel.json`. Esse arquivo é gerado pelo back a partir dos relatórios em `dados/brutos`, com o mesmo ETL que alimenta o banco (não precisa de Docker):

```powershell
cd back
python -m scripts.exportar_painel
```

Rode de novo sempre que entrarem relatórios novos. Os períodos ("Últimos 30d" etc.) contam a partir do último dia com dados, não de hoje.

## Como rodar

```bash
flutter pub get
flutter run -d chrome     # ou -d macos / dispositivo
flutter test
dart analyze lib test
```

## App no celular

O mesmo código gera o app de Android (pasta `android/`) e de iOS (pasta `ios/`). O app se chama **Ferret** e o identificador é `br.edu.maua.ferret`. Os dados e o mapa vão junto com o app, então ele funciona sem internet.

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
    autenticacao/               # contrato da recuperação de senha com o back
    router/app_router.dart      # GoRouter + ShellRoute + redirecionamentos
    theme/app_theme.dart        # AppColors, AppSpacing, AppTextStyles, AppTheme
  shared/
    painel.dart                 # modelo dos dados reais e painelProvider
    dados_exemplo.dart          # PontoSerie, modelos de relatório, sugestões do Ferret Jr
    formatters.dart             # número, moeda, data, percentual
    providers.dart              # período, linha escolhida, sessão e assistente
    widgets/
      app_shell.dart            # menu, header e PaginaConteudo
      app_widgets.dart          # AppCard, AppButton, AppTextField, TagFiltro...
      abas_pagina.dart          # abas ligadas ao ?aba= da rota
      faixa_indicadores.dart    # indicadores num card só, com mini-tendência
      barra_composicao.dart     # composição de um total numa barra de 100%
      mapa_calor.dart           # grade de cores (faixa horária × dia)
      mapa_municipio.dart       # mapa 3D com fluxos
      tabela_ordenavel.dart     # tabela que ordena pela coluna
      charts.dart               # linha, barras e barras horizontais
      filtro_periodo_bar.dart   # filtro de período compartilhado
  features/
    login/                      # login, esqueci minha senha e senha nova
    dashboard/ operacao/ financeiro/ dados/
    assistente/ relatorios/ configuracoes/
test/
  apoio/painel_teste.dart       # painel pequeno e fixo para os testes
  unit/  widget/
```

## Responsividade

- `< 700px` — mobile: 1 coluna, Drawer de navegação com a marca
- `700–1099px` — tablet: 2 colunas
- `>= 900px` — sidebar fixa de 252px + header
- `>= 1100px` — desktop: 4 colunas

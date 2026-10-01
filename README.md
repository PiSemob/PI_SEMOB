# Ferret — BI Platform (Frontend)

Plataforma de Business Intelligence e IA para gestão do transporte público municipal (SEMOB-SCS).
Projeto Integrador acadêmico — **apenas frontend**, sem backend, sem API, sem autenticação real.

## Identidade visual

Todos os tokens ficam em [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart):

| Token | Valor | Uso |
|---|---|---|
| `brandTop` / `brandBottom` | `#0B2338` / `#0E3233` | gradiente das superfícies escuras (login e sidebar) |
| `accent` | `#4ADE80` | destaque da marca sobre fundo escuro |
| `primary` | `#1D4ED8` | ação principal (botões, links, seleção) |
| `secondary` / `success` / `warning` / `danger` | — | séries de gráfico e estados |
| `background` / `surface` / `border` | `#EDF1F7` / `#FFFFFF` / `#E2E8F0` | superfícies claras |
| `AppSpacing` | 4 / 8 / 16 / 24 / 32 | espaçamento; raios 10 / 12 / pill |
| `AppTextStyles` | display, title, section, metric, body, label, caption, overline | tipografia |

Elementos de marca compartilhados em [lib/shared/widgets/app_widgets.dart](lib/shared/widgets/app_widgets.dart):
`AppLogo`, `FundoMarca` (gradiente + grade + brilho), `ChipMarca`.

## Como rodar

```bash
flutter pub get
flutter run -d chrome     # ou -d macos / dispositivo
flutter test
dart analyze lib test
```

## Estrutura

```
lib/
  main.dart
  core/
    router/app_router.dart      # GoRouter + ShellRoute
    theme/app_theme.dart        # AppColors, AppSpacing, AppTextStyles, AppTheme
  shared/
    dados_exemplo.dart          # dados mínimos para renderizar a UI
    formatters.dart             # número, moeda, data
    providers.dart              # filtros, sessão e assistente (Riverpod)
    widgets/
      app_shell.dart            # sidebar da marca + header + PaginaConteudo
      app_widgets.dart          # AppCard, AppMetricCard, AppButton, AppTextField,
                                # AppSectionTitle, EmptyState, GradeCards,
                                # AppLogo, FundoMarca, ChipMarca, Responsivo
      charts.dart               # GraficoLinha, GraficoBarras, GraficoPizza
      filtro_periodo_bar.dart   # filtro de período compartilhado
  features/
    login/ dashboard/ demanda/ receita/ creditos/
    frota/ quilometragem/ documentos/ assistente/ relatorios/
test/
  login_page_test.dart
  dashboard_page_test.dart
  providers_test.dart
```

## Responsividade

- `< 700px` — mobile: 1 coluna, Drawer de navegação com a marca
- `700–1099px` — tablet: 2 colunas
- `>= 900px` — sidebar fixa de 252px + header
- `>= 1100px` — desktop: 4 colunas

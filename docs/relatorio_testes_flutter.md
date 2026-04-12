# Relatorio de Testes Flutter - SMEnergy

Data da execucao: 2026-04-04
Projeto: SMEnergy
Escopo: Aplicacao Flutter e validacao tecnica complementar

## Resumo executivo

Foi expandida a base de testes automatizados da aplicacao SMEnergy para cobrir fluxos de autenticacao, registo, dashboard, historico, alertas, perfil, definicoes de eletricidade e onboarding do equipamento. Alem dos testes automatizados, foi efetuada uma validacao de analise estatica e uma compilacao Android da aplicacao Flutter.

Resultado global dos testes automatizados:

| Indicador | Valor |
| --- | --- |
| Total de testes executados | 32 |
| Testes aprovados | 32 |
| Testes reprovados | 0 |
| Taxa de sucesso | 100% |

Comando executado:

```powershell
flutter test -r expanded
```

Saida resumida:

```text
00:03 +32: All tests passed!
```

## Tipos de teste cobertos

| Tipo | Estado | Observacoes |
| --- | --- | --- |
| Unit tests | Executado | Modelos e logica de dominio ligada a sensores, tarifarios e gamificacao |
| Widget tests | Executado | Fluxos principais e estados de paginas Flutter |
| Smoke / build tests | Executado | `flutter analyze`, `flutter test` e `flutter build apk --debug` |
| Integration tests | Nao implementado nesta iteracao | Ainda nao foi criada suite `integration_test` com dispositivo/emulador |
| Golden tests | Nao implementado nesta iteracao | Ainda nao foram definidos snapshots visuais de referencia |
| Firmware build tests | Parcial | Nao foi possivel executar `pio run` por ausencia de PlatformIO no ambiente atual |

## Cobertura funcional implementada

Os testes atualmente implementados cobrem:

- `LoginPage`: campos vazios, credenciais invalidas, loading state, login Google e navegacao conforme existencia de equipamento;
- `RegisterPage`: campos vazios, passwords diferentes, validacoes de password e erro de email ja registado;
- `DashboardPage`: estado vazio e estado com metricas agregadas;
- `HistoryPage`: abertura sem crash e estado vazio;
- `AlertPage`: apresentacao de alerta ativo e acao de verificacao;
- `ProfilePage`: carregamento do perfil e fluxo de logout;
- `ElectricitySettingsPage`: validacao e gravacao de configuracao simples;
- onboarding: entrada em `AddEquipmentPage`, passo 1, passo 2, validacao de SSID e fluxo de configuracao com sucesso;
- modelos e logica de dominio: `EnergySensorSnapshot`, `ElectricityCostProfile` e `GamificationProfile`.

## Tabela resumida de casos de teste

| Grupo | Quantidade | Exemplos validados |
| --- | --- | --- |
| Login e registo | 15 | erros de autenticacao, Google Sign-In, loading, validacoes de password, email duplicado |
| Dashboard | 2 | estado vazio e metricas com sensores online/offline |
| Historico, alertas, perfil e eletricidade | 5 | estados vazios, alerta ativo, logout, validacao e gravacao de contrato eletrico |
| Onboarding do equipamento | 5 | acesso ao setup, Wi-Fi, reachability do equipamento, SSID vazio, configuracao concluida |
| Modelos e logica de dominio | 5 | progresso e alertas de sensor, custo estimado, parsing de perfil e progressao de gamificacao |

## Analise estatica

Comando executado:

```powershell
flutter analyze
```

Resultado:

- Sem erros bloqueantes nas alteracoes desta iteracao.
- Permanecem 5 ocorrencias preexistentes no projeto.

Tabela de ocorrencias identificadas:

| ID | Ficheiro | Tipo | Descricao |
| --- | --- | --- | --- |
| AN-01 | `lib/pages/History_page.dart` | Info | Nome do ficheiro fora da convencao `lower_case_with_underscores` |
| AN-02 | `lib/pages/add_equipment_page.dart` | Info | Uso de `withOpacity`, API marcada como deprecated |
| AN-03 | `lib/pages/equipSett_page.dart` | Info | Nome do ficheiro fora da convencao `lower_case_with_underscores` |
| AN-04 | `lib/services/config_service.dart` | Info | Inicializacao redundante com `null` |
| AN-05 | `lib/services/energy_data_service.dart` | Warning | Metodo `_aggregateHistoryByBuckets` sem utilizacao |

## Validacao de build

### Flutter Android

Comando executado:

```powershell
flutter build apk --debug
```

Resultado:

- Build concluido com sucesso.
- Artefacto gerado em `build/app/outputs/flutter-apk/app-debug.apk`.

### Firmware / PlatformIO

Tentativa de validacao:

- Foi verificada a disponibilidade da ferramenta `pio` / `platformio`.
- O ambiente atual nao possui PlatformIO instalado no `PATH`, pelo que nao foi possivel executar `pio run` ou `pio test`.

## Limites atuais da cobertura

Embora a cobertura tenha sido ampliada de forma significativa, permanecem alguns pontos fora do escopo desta iteracao:

- nao existe ainda suite formal de `integration_test` para fluxo completo em emulador/dispositivo;
- nao existem `golden tests` para comparacao visual de ecras;
- nao foi possivel validar o firmware com compilacao automatica por falta de PlatformIO no ambiente;
- paginas secundarias como `AccSettPage`, `EquipSettPage` e `GamificationPage` ainda nao receberam uma suite dedicada nesta iteracao.

## Texto curto para integrar no relatorio

Foi realizada uma validacao alargada da aplicacao SMEnergy com recurso a testes unitarios e testes de widget, cobrindo os principais fluxos de autenticacao, registo, dashboard, historico, alertas, perfil, definicoes de eletricidade e onboarding do equipamento. No total, foram executados 32 testes automaticos, todos concluídos com sucesso, o que corresponde a uma taxa de aprovacao de 100%. Complementarmente, foi executada a analise estatica do codigo e a compilacao Android da aplicacao Flutter, tendo ambas confirmado a estabilidade da iteracao, embora se mantenham algumas ocorrencias informativas e um aviso preexistente no projeto. A validacao automatica do firmware nao foi possivel nesta fase devido a indisponibilidade da ferramenta PlatformIO no ambiente de execucao.

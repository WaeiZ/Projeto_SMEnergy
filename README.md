# SMEnergy — Sistema Inteligente de Gestão de Energia Doméstica

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)
![ESP32](https://img.shields.io/badge/ESP32-Arduino%20Framework-E7352C?logo=espressif&logoColor=white)
![PlatformIO](https://img.shields.io/badge/PlatformIO-Firmware-F5822A?logo=platformio&logoColor=white)

> Projeto Final de Licenciatura em Engenharia Informática  
> Universidade Lusófona — Centro Universitário do Porto (CUP)  
> Ano letivo 2025/2026

---

## Documentos do Projeto

| Ficheiro | Localização |
|---|---|
| Relatório final (PDF) | [`docs/Doc_Projeto2_Final.pdf`](docs/Doc_Projeto2_Final.pdf) |
| Vídeo de demonstração da App | [YouTube](https://www.youtube.com/watch?v=cobi8yiz0zc) |
| Vídeo de demonstração do Equipamento | [YouTube](https://youtu.be/15BBA8nOQNc) |
---

## Sobre o Projeto

O **SMEnergy** é um sistema inteligente de monitorização e gestão de energia doméstica. Combina um equipamento IoT baseado em ESP32 com uma aplicação móvel Flutter para oferecer ao utilizador uma visão clara e em tempo real do seu consumo energético.

O problema central que este projeto resolve é a ausência de ferramentas intuitivas e acessíveis que permitam às famílias monitorizar o consumo elétrico doméstico, identificar desperdícios e receber recomendações personalizadas — tudo a um custo muito inferior às alternativas comerciais existentes.

### Objetivos principais

- **Eficiência energética** — monitorização contínua e análise de padrões de consumo
- **Redução de custos** — estimativa da fatura elétrica e alertas de consumo excessivo
- **Consciencialização ambiental** — incentivo a hábitos sustentáveis
- **Acessibilidade** — app multiplataforma (Android e iOS) com interface intuitiva
- **Inovação** — integração de IoT, análise de dados e gamificação

---

## Arquitetura

O sistema é composto por três camadas:

```
┌─────────────────────────────────────────────────────┐
│               Aplicação Móvel (Flutter)              │
│   Dashboard · Histórico · Alertas · Gamificação     │
└────────────────────┬────────────────────────────────┘
                     │ Firebase SDK
┌────────────────────▼────────────────────────────────┐
│                  Cloud Firebase                      │
│  Firestore · Auth · Cloud Functions · FCM           │
└────────────────────┬────────────────────────────────┘
                     │ Firebase_ESP_Client
┌────────────────────▼────────────────────────────────┐
│              Hardware IoT (ESP32)                    │
│   PZEM-004T · Display OLED · Provisioning Wi-Fi     │
└─────────────────────────────────────────────────────┘
```

- **Camada de Hardware** — O ESP32 recolhe leituras elétricas (tensão, corrente, potência, energia acumulada) através do sensor PZEM-004T e envia-as diretamente para o Firestore.
- **Camada Cloud** — O Firestore centraliza todos os dados; as Cloud Functions analisam leituras e disparam notificações push via FCM quando detetam consumo excessivo.
- **Camada Aplicacional** — A app Flutter consome os dados do Firestore em tempo quase real e apresenta-os ao utilizador.

---

## Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| **Autenticação** | Login/Registo com email, Google Sign-In, MFA e recuperação de password |
| **Onboarding do equipamento** | Configuração do ESP32 via access point local (provisioning Wi-Fi) |
| **Dashboard** | Monitorizar o consumo energético em tempo real |
| **Histórico** | Gráficos de consumo por período com exportação de relatórios em PDF |
| **Alertas** | Notificações push automáticas por consumo excessivo ou anomalias |
| **Estimativa de custos** | Cálculo da fatura elétrica estimada com base nas leituras recolhidas |
| **Gamificação** | Sistema de recompensas virtuais por redução de consumo |
| **Definições** | Gestão do perfil, configuração do equipamento e preferências de alerta |

---

## Stack Tecnológica

### Aplicação Móvel
- **Flutter + Dart** — base de código única para Android e iOS
- **Firebase Authentication** — autenticação com email/password, Google Sign-In e MFA
- **Cloud Firestore** — persistência de leituras e configurações
- **Firebase Cloud Messaging (FCM)** — notificações push
- **fl_chart** — visualização gráfica dos dados energéticos
- **pdf + printing** — exportação de relatórios

### Firmware e Hardware
- **ESP32** com framework Arduino
- **PZEM-004T** — sensor de grandezas elétricas (tensão, corrente, potência, energia)
- **Display OLED** — apresentação local de informação sem dependência da app
- **ESPAsyncWebServer + AsyncTCP** — provisioning local via access point
- **Firebase_ESP_Client** — autenticação e escrita direta no Firestore
- **PlatformIO** — ambiente de desenvolvimento e gestão de dependências do firmware

### Infraestrutura Cloud
- **Cloud Firestore** — repositório central (utilizadores, dispositivos, leituras, alertas)
- **Cloud Functions** — análise de consumo e envio de notificações 
- **Firebase Authentication** — gestão de sessões e UID

### Ferramentas de Desenvolvimento
- **GitHub** — Controlo de versões do Projeto
- **PlatformIO** — compilação e gestão do firmware

---

## Estrutura do Repositório

```
SMEnergy/
├── lib/                  # Aplicação móvel Flutter
│   ├── screens/          # Ecrãs (dashboard, histórico, alertas, perfil, etc.)
│   ├── services/         # Lógica e integração com Firebase
│   └── widgets/          # Componentes reutilizáveis
├── firmware/             # Firmware PlatformIO para ESP32
│   ├── src/              # Código fonte do firmware
│   └── platformio.ini    # Configuração do projeto PlatformIO
└── docs/                 # Relatório de Projeto Final de Licenciatura e APK
```

---

## Pré-requisitos

### Aplicação Móvel
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão estável mais recente)
- Dart (incluído no Flutter SDK)
- Android Studio ou Xcode (para emulador/dispositivo físico)
- Conta Google com projeto Firebase criado

### Firmware
- [PlatformIO](https://platformio.org/install) (extensão VS Code ou CLI)
- Hardware físico necessário e montado:
  - ESP32 (com conectividade Wi-Fi integrada)
  - Sensor PZEM-004T (medição de tensão, corrente, potência e energia)
  - Display OLED SSD1306
---

## Instalação e Execução

### 1. Clonar o repositório

```bash
git clone https://github.com/WaeiZ/Projeto_SMEnergy.git
cd Projeto_SMEnergy
```

### 2. Configurar o Firebase

1. Criar um projeto em [Firebase Console](https://console.firebase.google.com/)
2. Ativar **Authentication** (Email/Password + Google Sign-In)
3. Criar uma base de dados **Cloud Firestore**
4. Ativar **Cloud Messaging (FCM)**
5. Adicionar a app Android/iOS ao projeto Firebase e descarregar:
   - `google-services.json` → colocar em `android/app/`
   - `GoogleService-Info.plist` → colocar em `ios/Runner/`

### 3. Correr a aplicação Flutter

```bash
flutter pub get
flutter run
```

### 4. Compilar e carregar o firmware

```bash
cd firmware
# Editar as credenciais Wi-Fi e Firebase em src/config.h (se aplicável)
pio run --target upload
```

Após o upload, o ESP32 cria um access point local. Usa a app para configurar a ligação Wi-Fi e associar o dispositivo à tua conta.

## Autor

**Sérgio Dias** — a22304791  
Licenciatura em Engenharia Informática — Projeto II  
Universidade Lusófona, Centro Universitário do Porto (CUP)  
Orientador: Hugo Barbosa

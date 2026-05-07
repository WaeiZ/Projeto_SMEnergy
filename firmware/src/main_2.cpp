#define ENABLE_USER_AUTH
#define ENABLE_FIRESTORE
#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <Preferences.h>
#include <time.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <PZEM004Tv30.h>
#include <FirebaseClient.h>

// --- FIREBASE ---
#define FIREBASE_API_KEY      "AIzaSyAKyEa3odhids7FTxO_6lutEET0yItJi_c"
#define FIREBASE_PROJECT_ID   "smenergy-14cc7"
#define FIREBASE_USER_EMAIL   "esp32@gmail.com"
#define FIREBASE_USER_PASSWORD "12345678"

// --- Provisioning AP ---
#define WIFI_AP_NAME            "SMEnergy_AP"
#define WIFI_CONNECT_TIMEOUT_MS 30000UL
#define WIFI_RETRY_INTERVAL_MS  15000UL

// --- Display ---
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64

// --- Loop ---
#define SENSOR_LOOP_DELAY_MS    60000UL
#define RESET_CHECK_INTERVAL_MS 2000UL

// --- Preferences ---
#define PREF_NAMESPACE "smenergy"
#define PREF_KEY_SSID  "wifi_ssid"
#define PREF_KEY_PASS  "wifi_pass"
#define PREF_KEY_UID   "owner_uid"

// ─────────────────────────────────────────────
// Hardware
// ─────────────────────────────────────────────
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

PZEM004Tv30 pzem1(Serial2, 16, 17, 0x01);
PZEM004Tv30 pzem2(Serial2, 16, 17, 0x02);
PZEM004Tv30 pzem3(Serial2, 16, 17, 0x03);

// ─────────────────────────────────────────────
// FirebaseClient — objetos globais
// ─────────────────────────────────────────────
WiFiClientSecure ssl_client1;   // para leituras (get)
WiFiClientSecure ssl_client2;   // para escritas (patch/create)

UserAuth user_auth(FIREBASE_API_KEY, FIREBASE_USER_EMAIL, FIREBASE_USER_PASSWORD, 3000);
FirebaseApp app;

AsyncClientClass aClientRead(ssl_client1);
AsyncClientClass aClientWrite(ssl_client2);

Firestore::Documents Docs;

AsyncResult aResultRead;
AsyncResult aResultWrite;

bool firebaseInitialized = false;

// ─────────────────────────────────────────────
// Provisioning / estado global
// ─────────────────────────────────────────────
AsyncWebServer provisioningServer(80);
Preferences prefs;

String deviceID;
String ownerUID;
String configuredSSID;
String configuredPassword;

String pendingSSID;
String pendingPassword;
String pendingOwnerUID;
bool provisioningPending   = false;
bool serverStarted         = false;
bool provisioningApActive  = false;

uint32_t readingCounter    = 0;
unsigned long lastResetCheckMs = 0;
unsigned long lastWifiRetryMs  = 0;
unsigned long lastAuthRefreshMs = 0;

// ─────────────────────────────────────────────
// Sensores
// ─────────────────────────────────────────────
struct SensorDef {
  PZEM004Tv30 *pzem;
  const char  *id;
  const char  *name;
  int          phase;
  bool         enabled;
};

SensorDef sensors[] = {
  {&pzem1, "sensor_1", "Sensor 1", 1, true},
  {&pzem2, "sensor_2", "Sensor 2", 2, true},
  {&pzem3, "sensor_3", "Sensor 3", 3, true},
};
const size_t SENSOR_COUNT = sizeof(sensors) / sizeof(sensors[0]);

// ─────────────────────────────────────────────
// Utilitários
// ─────────────────────────────────────────────
String boolToJson(bool v) { return v ? "true" : "false"; }

String buildDeviceId() {
  uint64_t chip = ESP.getEfuseMac();
  char buff[13];
  snprintf(buff, sizeof(buff), "%04X%08X", (uint16_t)(chip >> 32), (uint32_t)chip);
  return String(buff);
}

String nowIsoUtc() {
  time_t ts = time(nullptr);
  struct tm tmUtc;
  gmtime_r(&ts, &tmUtc);
  char iso[25];
  strftime(iso, sizeof(iso), "%Y-%m-%dT%H:%M:%SZ", &tmUtc);
  return String(iso);
}

// ─────────────────────────────────────────────
// Paths Firestore
// ─────────────────────────────────────────────
String deviceDocPath() {
  return "users/" + ownerUID + "/devices/" + deviceID;
}
String sensorDocPath(const char *sensorId) {
  return deviceDocPath() + "/sensors/" + sensorId;
}
String sensorReadingsPath(const char *sensorId) {
  return sensorDocPath(sensorId) + "/readings";
}

// ─────────────────────────────────────────────
// OLED
// ─────────────────────────────────────────────
void showOledStatus(
  const String &title,
  const String &line1 = "",
  const String &line2 = "",
  const String &line3 = ""
) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println(title);
  display.drawLine(0, 10, 128, 10, WHITE);
  display.setCursor(0, 18);
  if (line1.length()) display.println(line1);
  if (line2.length()) display.println(line2);
  if (line3.length()) display.println(line3);
  display.display();
}

// ─────────────────────────────────────────────
// NTP
// ─────────────────────────────────────────────
void syncClock() {
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("A sincronizar relogio");
  time_t now = time(nullptr);
  int retries = 0;
  while (now < 1700000000 && retries < 30) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
    retries++;
  }
  Serial.println();
  if (now >= 1700000000) {
    Serial.println("Relogio sincronizado.");
  } else {
    Serial.println("Falha ao sincronizar relogio.");
    showOledStatus("SMEnergy", "Hora indisponivel", "Segue em frente");
  }
}

// ─────────────────────────────────────────────
// PZEM
// ─────────────────────────────────────────────
void initSensorsIfNeeded() {
  Serial2.begin(9600, SERIAL_8N1, 16, 17);
}

// ─────────────────────────────────────────────
// Preferences
// ─────────────────────────────────────────────
void loadProvisioning() {
  prefs.begin(PREF_NAMESPACE, false);
  configuredSSID     = prefs.getString(PREF_KEY_SSID, "");
  configuredPassword = prefs.getString(PREF_KEY_PASS, "");
  ownerUID           = prefs.getString(PREF_KEY_UID,  "");
  Serial.println("Provisioning SSID: " + (configuredSSID.length() ? configuredSSID : "(vazio)"));
  Serial.println("Provisioning UID:  " + (ownerUID.length()       ? ownerUID       : "(vazio)"));
}

void saveProvisioning(const String &ssid, const String &password, const String &uid) {
  prefs.putString(PREF_KEY_SSID, ssid);
  prefs.putString(PREF_KEY_PASS, password);
  prefs.putString(PREF_KEY_UID,  uid);
  configuredSSID     = ssid;
  configuredPassword = password;
  ownerUID           = uid;
}

void clearProvisioning() {
  prefs.remove(PREF_KEY_SSID);
  prefs.remove(PREF_KEY_PASS);
  prefs.remove(PREF_KEY_UID);
  configuredSSID = configuredPassword = ownerUID = "";
}

// ─────────────────────────────────────────────
// Wi-Fi
// ─────────────────────────────────────────────
bool connectToWifi(const String &ssid, const String &password) {
  if (!ssid.length()) return false;
  showOledStatus("SMEnergy", "Ligar ao Wi-Fi", ssid);
  WiFi.softAPdisconnect(true);
  provisioningApActive = false;
  delay(200);
  WiFi.disconnect(true, true);
  delay(200);
  WiFi.setSleep(false);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid.c_str(), password.c_str());
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < WIFI_CONNECT_TIMEOUT_MS) {
    delay(250);
  }
  bool ok = WiFi.status() == WL_CONNECTED;
  Serial.println(ok ? "WiFi: CONNECTED" : "WiFi: FAILED");
  if (ok) showOledStatus("SMEnergy", "Wi-Fi ligado", WiFi.localIP().toString());
  else    showOledStatus("SMEnergy", "Falha no Wi-Fi", ssid, "Abrir modo AP");
  return ok;
}

void restartForProvisioning() {
  clearProvisioning();
  showOledStatus("SMEnergy", "Reset recebido", "A reiniciar...");
  WiFi.disconnect(true, true);
  delay(300);
  ESP.restart();
}

// ─────────────────────────────────────────────
// Firebase — init
// ─────────────────────────────────────────────
void initFirebaseIfNeeded() {
  if (firebaseInitialized) return;

  showOledStatus("SMEnergy", "Ligar Firebase");
  Serial.print("Heap antes Firebase: ");
  Serial.println(ESP.getFreeHeap());

  ssl_client1.setInsecure();   // aceita certificados sem validação de CA
  ssl_client2.setInsecure();

  initializeApp(aClientRead, app, getAuth(user_auth), 120 * 1000);
  app.getApp<Firestore::Documents>(Docs);

  firebaseInitialized = true;
  showOledStatus("SMEnergy", "Firebase pronto");
  Serial.println("Firebase inicializado.");
}

bool waitForAppReady(unsigned long timeoutMs) {
  initFirebaseIfNeeded();
  unsigned long start = millis();
  while (!app.ready() && millis() - start < timeoutMs) {
    app.loop();
    delay(100);
  }
  return app.ready();
}

// ─────────────────────────────────────────────
// Firestore — helpers síncronos
// ─────────────────────────────────────────────

// Constrói um Document Firestore com os campos fornecidos (via FirebaseJson/object_t)
// e executa patch síncrono, retornando true em caso de sucesso.
void logFirestoreFailure(const char *operation, AsyncClientClass &ac, const String &result) {
  Serial.print("[Firestore] ");
  Serial.print(operation);
  Serial.print(" erro: ");
  Serial.println(ac.lastError().message().c_str());

  if (result.length() > 0) {
    Serial.print("[Firestore] ");
    Serial.print(operation);
    Serial.print(" resposta: ");
    Serial.println(result);
  }

  String errorMessage = ac.lastError().message().c_str();
  bool authError =
    ac.lastError().code() == 401 ||
    errorMessage.indexOf("unauthorized") >= 0 ||
    result.indexOf("UNAUTHENTICATED") >= 0 ||
    result.indexOf("Missing or invalid authentication") >= 0;

  if (authError && millis() - lastAuthRefreshMs > 10000UL) {
    lastAuthRefreshMs = millis();
    Serial.println("[Firebase] Token invalido/expirado. A renovar autenticacao...");
    app.authenticate();
  }
}

bool firestorePatch(
  AsyncClientClass &ac,
  const String &docPath,
  Document<Values::Value> &doc,
  const String &updateMask
) {
  PatchDocumentOptions opts(
    DocumentMask(updateMask.c_str()),  // updateMask
    DocumentMask(""),                  // mask (campos a retornar)
    Precondition()                     // sem precondição
  );

  String result = Docs.patch(
    ac,
    Firestore::Parent(FIREBASE_PROJECT_ID),
    docPath,
    opts,
    doc
  );

  if (ac.lastError().code() != 0) {
    logFirestoreFailure("patch", ac, result);
    return false;
  }
  return true;
}

bool firestoreCommitUpdate(
  AsyncClientClass &ac,
  const String &docPath,
  Document<Values::Value> &doc,
  const String &updateMask
) {
  doc.setName(docPath);
  Writes writes(Write(DocumentMask(updateMask.c_str()), doc, Precondition()));

  String result = Docs.commit(
    ac,
    Firestore::Parent(FIREBASE_PROJECT_ID),
    writes
  );

  if (ac.lastError().code() != 0) {
    logFirestoreFailure("commit", ac, result);
    return false;
  }
  return true;
}

bool firestoreCreate(
  AsyncClientClass &ac,
  const String &collectionPath,
  const String &docId,
  Document<Values::Value> &doc
) {
  String documentPath = collectionPath + "/" + docId;
  String result = Docs.createDocument(
    ac,
    Firestore::Parent(FIREBASE_PROJECT_ID),
    documentPath,
    DocumentMask(),
    doc
  );

  if (ac.lastError().code() != 0) {
    logFirestoreFailure("create", ac, result);
    return false;
  }
  return true;
}

bool firestoreGet(
  AsyncClientClass &ac,
  const String &docPath,
  const String &fieldMask,
  String       &payloadOut
) {
  GetDocumentOptions opts(DocumentMask(fieldMask.c_str()));
  payloadOut = Docs.get(
    ac,
    Firestore::Parent(FIREBASE_PROJECT_ID),
    docPath,
    opts
  );

  if (ac.lastError().code() != 0) {
    // código 404 é esperado se o documento não existir
    if (ac.lastError().code() != 404) {
      logFirestoreFailure("get", ac, payloadOut);
    }
    return false;
  }
  return true;
}

// ─────────────────────────────────────────────
// Upsert device doc
// ─────────────────────────────────────────────
bool upsertDeviceDoc(const String &ts, bool clearUnpaired = false) {
  Document<Values::Value> doc("name", Values::Value(Values::StringValue("SMEnergy " + deviceID)));
  doc.add("source", Values::Value(Values::StringValue("esp32_pzem")));
  doc.add("placeholder", Values::Value(Values::BooleanValue(false)));
  doc.add("is_online", Values::Value(Values::BooleanValue(true)));
  doc.add("local_ip", Values::Value(Values::StringValue(WiFi.localIP().toString())));
  doc.add("last_seen", Values::Value(Values::TimestampValue(ts)));

  String mask = "name,source,placeholder,is_online,local_ip,last_seen";

  if (clearUnpaired) {
    doc.add("command", Values::Value(Values::StringValue("")));
    doc.add("unpaired", Values::Value(Values::BooleanValue(false)));
    mask += ",command,unpaired";
  }

  return firestoreCommitUpdate(aClientWrite, deviceDocPath(), doc, mask);
}

// ─────────────────────────────────────────────
// Upsert sensor doc
// ─────────────────────────────────────────────
bool upsertSensorDoc(
  const SensorDef &sensor,
  float watts, float voltage, float current, float energy,
  const String &ts
) {
  Document<Values::Value> doc("sensor_name", Values::Value(Values::StringValue(sensor.name)));
  doc.add("source", Values::Value(Values::StringValue("esp32_pzem")));
  doc.add("placeholder", Values::Value(Values::BooleanValue(false)));
  doc.add("phase", Values::Value(Values::IntegerValue(sensor.phase)));
  doc.add("current_watts", Values::Value(Values::DoubleValue(number_t(watts, 3))));
  doc.add("voltage", Values::Value(Values::DoubleValue(number_t(voltage, 3))));
  doc.add("current", Values::Value(Values::DoubleValue(number_t(current, 3))));
  doc.add("energy", Values::Value(Values::DoubleValue(number_t(energy, 6))));
  doc.add("is_online", Values::Value(Values::BooleanValue(true)));
  doc.add("last_reading_at", Values::Value(Values::TimestampValue(ts)));

  return firestoreCommitUpdate(
    aClientWrite,
    sensorDocPath(sensor.id),
    doc,
    "sensor_name,source,placeholder,phase,current_watts,voltage,current,energy,is_online,last_reading_at"
  );
}

// ─────────────────────────────────────────────
// Add reading
// ─────────────────────────────────────────────
bool addReading(
  const SensorDef &sensor,
  float watts, float voltage, float current, float energy,
  const String &ts
) {
  Document<Values::Value> doc("timestamp", Values::Value(Values::TimestampValue(ts)));
  doc.add("watts", Values::Value(Values::DoubleValue(number_t(watts, 3))));
  doc.add("source", Values::Value(Values::StringValue("esp32_pzem")));
  doc.add("voltage", Values::Value(Values::DoubleValue(number_t(voltage, 3))));
  doc.add("current", Values::Value(Values::DoubleValue(number_t(current, 3))));
  doc.add("energy", Values::Value(Values::DoubleValue(number_t(energy, 6))));
  doc.add("phase", Values::Value(Values::IntegerValue(sensor.phase)));

  String docId = String(sensor.id) + "_" + String((uint32_t)time(nullptr)) + "_" + String(readingCounter++);
  return firestoreCreate(aClientWrite, sensorReadingsPath(sensor.id), docId, doc);
}

// ─────────────────────────────────────────────
// Check reset remoto
// ─────────────────────────────────────────────
void checkRemoteReset(bool force = false) {
  if (!app.ready()) return;

  unsigned long nowMs = millis();
  if (!force && nowMs - lastResetCheckMs < RESET_CHECK_INTERVAL_MS) return;
  lastResetCheckMs = nowMs;

  String payload;
  if (!firestoreGet(aClientRead, deviceDocPath(), "command,unpaired", payload)) return;

  // Verificar command: reset
  bool resetRequested   = payload.indexOf("\"stringValue\":\"reset\"") >= 0;
  // Verificar unpaired: true
  bool unpairedRequested = payload.indexOf("\"booleanValue\":true") >= 0
                        && payload.indexOf("unpaired") >= 0;

  if (!resetRequested && !unpairedRequested) return;

  Serial.println(resetRequested ? "Comando remoto: reset" : "Comando remoto: unpaired");

  // Tenta limpar o comando (se falhar, reinicia na mesma)
  Document<Values::Value> doc("command", Values::Value(Values::StringValue("")));
  doc.add("is_online", Values::Value(Values::BooleanValue(false)));
  firestoreCommitUpdate(aClientWrite, deviceDocPath(), doc, "command,is_online");

  restartForProvisioning();
}

// ─────────────────────────────────────────────
// Delay com verificação de reset
// ─────────────────────────────────────────────
void delayWithRemoteResetCheck(unsigned long delayMs) {
  unsigned long start = millis();
  while (millis() - start < delayMs) {
    app.loop();  // necessário para manter o token vivo
    if (WiFi.status() == WL_CONNECTED && app.ready() && ownerUID.length()) {
      checkRemoteReset();
    }
    delay(1000);
  }
}

// ─────────────────────────────────────────────
// Provisioning HTTP server
// ─────────────────────────────────────────────
void ensureProvisioningRoutes() {
  if (serverStarted) return;

  provisioningServer.on("/status", HTTP_GET, [](AsyncWebServerRequest *request) {
    String p = "{";
    p += "\"device_id\":\"" + deviceID + "\",";
    p += "\"ap_ssid\":\"" + String(WIFI_AP_NAME) + "\",";
    p += "\"wifi_connected\":" + boolToJson(WiFi.status() == WL_CONNECTED) + ",";
    p += "\"owner_uid_configured\":" + boolToJson(ownerUID.length() > 0);
    p += "}";
    request->send(200, "application/json", p);
  });

  provisioningServer.on("/provision", HTTP_POST, [](AsyncWebServerRequest *request) {
    if (!request->hasParam("ssid", true) ||
        !request->hasParam("password", true) ||
        !request->hasParam("owner_uid", true)) {
      request->send(400, "application/json", "{\"error\":\"missing ssid/password/owner_uid\"}");
      return;
    }
    String ssid = request->getParam("ssid", true)->value();
    String pass = request->getParam("password", true)->value();
    String uid  = request->getParam("owner_uid", true)->value();
    ssid.trim(); uid.trim();
    if (!ssid.length() || !uid.length()) {
      request->send(400, "application/json", "{\"error\":\"ssid and owner_uid required\"}");
      return;
    }
    pendingSSID     = ssid;
    pendingPassword = pass;
    pendingOwnerUID = uid;
    provisioningPending = true;
    request->send(202, "application/json", "{\"status\":\"accepted\"}");
  });

  auto resetHandler = [](AsyncWebServerRequest *request) {
    request->send(202, "application/json", "{\"status\":\"resetting\"}");
    restartForProvisioning();
  };
  provisioningServer.on("/reset", HTTP_POST, resetHandler);
  provisioningServer.on("/reset", HTTP_GET,  resetHandler);

  provisioningServer.onNotFound([](AsyncWebServerRequest *request) {
    request->send(404, "application/json", "{\"error\":\"not found\"}");
  });

  provisioningServer.begin();
  serverStarted = true;
}

void setupProvisioningServer() {
  if (provisioningApActive) {
    showOledStatus("Modo configuracao", "Ligue ao AP:", WIFI_AP_NAME, WiFi.softAPIP().toString());
    return;
  }
  WiFi.softAPdisconnect(true);
  provisioningApActive = false;
  delay(200);
  WiFi.disconnect(true, true);
  delay(200);
  WiFi.setSleep(false);
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(IPAddress(192,168,4,1), IPAddress(192,168,4,1), IPAddress(255,255,255,0));
  bool ok = WiFi.softAP(WIFI_AP_NAME, nullptr, 6, false, 4);
  provisioningApActive = ok;
  Serial.println(ok ? "AP ativo" : "AP FALHOU");
  ensureProvisioningRoutes();
  showOledStatus(
    "Modo configuracao",
    ok ? "Ligue ao AP:" : "Erro ao abrir AP",
    ok ? WIFI_AP_NAME : "",
    ok ? WiFi.softAPIP().toString() : ""
  );
}

// ─────────────────────────────────────────────
// Processar provisioning pendente
// ─────────────────────────────────────────────
void processProvisioningRequestIfAny() {
  if (!provisioningPending) return;
  showOledStatus("SMEnergy", "Recebido setup", "A aplicar...");
  provisioningPending = false;
  saveProvisioning(pendingSSID, pendingPassword, pendingOwnerUID);
  bool connected = connectToWifi(configuredSSID, configuredPassword);
  if (connected) {
    ensureProvisioningRoutes();
    syncClock();
    initSensorsIfNeeded();
    Serial.println("Provisioning concluido.");
  } else {
    Serial.println("Falha Wi-Fi apos provisioning.");
    setupProvisioningServer();
  }
}

// ─────────────────────────────────────────────
// Manter ligação Wi-Fi
// ─────────────────────────────────────────────
void maintainWiFiConnection() {
  if (!configuredSSID.length()) {
    setupProvisioningServer();
    return;
  }
  if (WiFi.status() == WL_CONNECTED) return;
  if (provisioningApActive) return;
  unsigned long nowMs = millis();
  if (nowMs - lastWifiRetryMs < WIFI_RETRY_INTERVAL_MS) return;
  lastWifiRetryMs = nowMs;
  if (!connectToWifi(configuredSSID, configuredPassword)) {
    setupProvisioningServer();
  } else {
    ensureProvisioningRoutes();
    syncClock();
    initSensorsIfNeeded();
  }
}

// ─────────────────────────────────────────────
// Ler sensor e publicar
// ─────────────────────────────────────────────
bool readAndPublish(const SensorDef &sensor) {
  float voltage = sensor.pzem->voltage();
  float watts   = sensor.pzem->power();
  float current = sensor.pzem->current();
  float energy  = sensor.pzem->energy();

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print("SISTEMA TRIFASICO - F");
  display.println(sensor.phase);
  display.drawLine(0, 10, 128, 10, WHITE);
  display.setCursor(0, 25);

  if (isnan(voltage) || isnan(watts) || isnan(current) || isnan(energy)) {
    display.println("ERRO SENSOR " + String(sensor.id));
    display.display();
    return false;
  }

  display.setTextSize(2);
  display.print((int)watts);
  display.println(" W");
  display.setTextSize(1);
  display.print(voltage, 1); display.print("V | ");
  display.print(current, 2); display.println("A");
  display.display();

  if (WiFi.status() != WL_CONNECTED || !ownerUID.length()) return true;

  if (!waitForAppReady(8000UL)) {
    Serial.println("Firebase indisponivel, leitura local mantida.");
    return true;
  }

  app.loop();  // processar token/auth

  String ts = nowIsoUtc();
  upsertDeviceDoc(ts);
  upsertSensorDoc(sensor, watts, voltage, current, energy, ts);
  addReading(sensor, watts, voltage, current, energy, ts);
  return true;
}

// ─────────────────────────────────────────────
// Setup
// ─────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.print("Heap inicial: ");
  Serial.println(ESP.getFreeHeap());

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED Erro");
  }
  display.setTextColor(WHITE);
  showOledStatus("SMEnergy", "A iniciar...");

  deviceID = buildDeviceId();
  loadProvisioning();

  if (!configuredSSID.length() || !ownerUID.length()) {
    setupProvisioningServer();
    return;
  }

  bool connected = connectToWifi(configuredSSID, configuredPassword);
  if (connected) {
    ensureProvisioningRoutes();
    syncClock();
    initSensorsIfNeeded();
    initFirebaseIfNeeded();
  } else {
    setupProvisioningServer();
  }
}

// ─────────────────────────────────────────────
// Loop
// ─────────────────────────────────────────────
void loop() {
  app.loop();  // manter token Firebase vivo

  processProvisioningRequestIfAny();
  maintainWiFiConnection();

  if (provisioningApActive) {
    delay(250);
    return;
  }

  if (WiFi.status() == WL_CONNECTED && app.ready() && ownerUID.length()) {
    checkRemoteReset();
  }

  for (size_t i = 0; i < SENSOR_COUNT; i++) {
    if (!sensors[i].enabled) continue;

    // Verifica reset antes de cada sensor
    if (WiFi.status() == WL_CONNECTED && app.ready() && ownerUID.length()) {
      checkRemoteReset(true);
    }

    readAndPublish(sensors[i]);
  }

  delayWithRemoteResetCheck(SENSOR_LOOP_DELAY_MS);

  if (WiFi.status() == WL_CONNECTED && app.ready() && ownerUID.length()) {
    checkRemoteReset();
  }
}

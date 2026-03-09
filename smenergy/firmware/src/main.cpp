#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <Preferences.h>
#include <time.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <PZEM004Tv30.h>
#include <FirebaseESP32.h>

// --- FIREBASE (Firestore) ---
#define FIREBASE_API_KEY "sua-api-key"
#define FIREBASE_PROJECT_ID "seu-projeto-id"
#define FIREBASE_USER_EMAIL "utilizador@dominio.com"
#define FIREBASE_USER_PASSWORD "sua-password"

// Opcional: UID default caso ainda não tenha sido enviado pela app.
#define FIREBASE_OWNER_UID ""

#define FIRESTORE_DB_ID ""

// --- Provisioning AP ---
#define WIFI_AP_NAME "SMEnergy_AP"
#define WIFI_CONNECT_TIMEOUT_MS 30000UL
#define WIFI_RETRY_INTERVAL_MS 15000UL

// --- Loop / leituras ---
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define SENSOR_DEFAULT_LIMIT_WATTS 600.0
#define SENSOR_LOOP_DELAY_MS 3000
#define RESET_CHECK_INTERVAL_MS 10000UL

#define PREF_NAMESPACE "smenergy"
#define PREF_KEY_SSID "wifi_ssid"
#define PREF_KEY_PASS "wifi_pass"
#define PREF_KEY_UID "owner_uid"

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Instâncias com endereços diferentes no mesmo barramento Serial2 (16, 17)
PZEM004Tv30 pzem1(Serial2, 16, 17, 0x01);
PZEM004Tv30 pzem2(Serial2, 16, 17, 0x02);
PZEM004Tv30 pzem3(Serial2, 16, 17, 0x03);

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

AsyncWebServer provisioningServer(80);
Preferences prefs;

String deviceID;
String ownerUID;
String configuredSSID;
String configuredPassword;

String pendingSSID;
String pendingPassword;
String pendingOwnerUID;
bool provisioningPending = false;
bool serverStarted = false;
bool firebaseInitialized = false;

uint32_t readingCounter = 0;
unsigned long lastResetCheckMs = 0;
unsigned long lastWifiRetryMs = 0;

struct SensorDef {
  PZEM004Tv30 *pzem;
  const char *id;
  const char *name;
  int phase;
};

SensorDef sensors[] = {
  {&pzem1, "sensor_1", "Sensor 1", 1},
  {&pzem2, "sensor_2", "Sensor 2", 2},
  {&pzem3, "sensor_3", "Sensor 3", 3},
};

String boolToJson(bool value) {
  return value ? "true" : "false";
}

String buildDeviceId() {
  uint64_t chip = ESP.getEfuseMac();
  char buff[13];
  snprintf(buff, sizeof(buff), "%04X%08X", (uint16_t)(chip >> 32), (uint32_t)chip);
  return String(buff);
}

String nowIsoUtc() {
  time_t ts = Firebase.getCurrentTime();
  if (ts <= 0) {
    ts = time(nullptr);
  }
  struct tm tmUtc;
  gmtime_r(&ts, &tmUtc);
  char iso[25];
  strftime(iso, sizeof(iso), "%Y-%m-%dT%H:%M:%SZ", &tmUtc);
  return String(iso);
}

String deviceDocPath() {
  return "users/" + ownerUID + "/devices/" + deviceID;
}

String sensorDocPath(const char *sensorId) {
  return deviceDocPath() + "/sensors/" + sensorId;
}

String sensorReadingsCollectionPath(const char *sensorId) {
  return sensorDocPath(sensorId) + "/readings";
}

void logFirebaseError(const char *context) {
  Serial.print("[Firebase] ");
  Serial.print(context);
  Serial.print(" -> ");
  Serial.println(fbdo.errorReason());
}

void loadProvisioning() {
  prefs.begin(PREF_NAMESPACE, false);
  configuredSSID = prefs.getString(PREF_KEY_SSID, "");
  configuredPassword = prefs.getString(PREF_KEY_PASS, "");
  ownerUID = prefs.getString(PREF_KEY_UID, "");

  if (ownerUID.length() == 0 && strlen(FIREBASE_OWNER_UID) > 0) {
    ownerUID = FIREBASE_OWNER_UID;
  }
}

void saveProvisioning(const String &ssid, const String &password, const String &uid) {
  prefs.putString(PREF_KEY_SSID, ssid);
  prefs.putString(PREF_KEY_PASS, password);
  prefs.putString(PREF_KEY_UID, uid);

  configuredSSID = ssid;
  configuredPassword = password;
  ownerUID = uid;
}

void clearProvisioning() {
  prefs.remove(PREF_KEY_SSID);
  prefs.remove(PREF_KEY_PASS);
  prefs.remove(PREF_KEY_UID);

  configuredSSID = "";
  configuredPassword = "";
  ownerUID = "";
}

bool connectToWifi(const String &ssid, const String &password) {
  if (ssid.length() == 0) {
    return false;
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid.c_str(), password.c_str());

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - start) < WIFI_CONNECT_TIMEOUT_MS) {
    delay(250);
  }

  bool connected = WiFi.status() == WL_CONNECTED;
  Serial.print("WiFi status: ");
  Serial.println(connected ? "CONNECTED" : "FAILED");
  return connected;
}

void setupProvisioningServer() {
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(WIFI_AP_NAME);

  if (serverStarted) {
    return;
  }

  provisioningServer.on("/status", HTTP_GET, [](AsyncWebServerRequest *request) {
    String payload = "{";
    payload += "\"device_id\":\"" + deviceID + "\",";
    payload += "\"ap_ssid\":\"" + String(WIFI_AP_NAME) + "\",";
    payload += "\"wifi_connected\":" + boolToJson(WiFi.status() == WL_CONNECTED) + ",";
    payload += "\"owner_uid_configured\":" + boolToJson(ownerUID.length() > 0);
    payload += "}";
    request->send(200, "application/json", payload);
  });

  provisioningServer.on("/provision", HTTP_POST, [](AsyncWebServerRequest *request) {
    bool hasSsid = request->hasParam("ssid", true);
    bool hasPassword = request->hasParam("password", true);
    bool hasOwnerUid = request->hasParam("owner_uid", true);

    if (!hasSsid || !hasPassword || !hasOwnerUid) {
      request->send(400, "application/json", "{\"error\":\"missing ssid/password/owner_uid\"}");
      return;
    }

    String ssid = request->getParam("ssid", true)->value();
    String password = request->getParam("password", true)->value();
    String uid = request->getParam("owner_uid", true)->value();

    ssid.trim();
    uid.trim();
    if (ssid.length() == 0 || uid.length() == 0) {
      request->send(400, "application/json", "{\"error\":\"ssid and owner_uid are required\"}");
      return;
    }

    pendingSSID = ssid;
    pendingPassword = password;
    pendingOwnerUID = uid;
    provisioningPending = true;

    request->send(202, "application/json", "{\"status\":\"accepted\"}");
  });

  provisioningServer.onNotFound([](AsyncWebServerRequest *request) {
    request->send(404, "application/json", "{\"error\":\"not found\"}");
  });

  provisioningServer.begin();
  serverStarted = true;

  Serial.print("Provisioning AP ativo: ");
  Serial.println(WIFI_AP_NAME);
  Serial.print("IP AP: ");
  Serial.println(WiFi.softAPIP());
}

void initFirebaseIfNeeded() {
  if (firebaseInitialized) {
    return;
  }

  config.api_key = FIREBASE_API_KEY;
  auth.user.email = FIREBASE_USER_EMAIL;
  auth.user.password = FIREBASE_USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  firebaseInitialized = true;
}

bool patchDocument(const String &path, FirebaseJson &content, const char *updateMask) {
  bool ok = Firebase.Firestore.patchDocument(
    &fbdo,
    FIREBASE_PROJECT_ID,
    FIRESTORE_DB_ID,
    path.c_str(),
    content.raw(),
    updateMask
  );
  if (!ok) {
    logFirebaseError("patchDocument");
  }
  return ok;
}

void upsertDeviceDoc(const String &timestampIso) {
  FirebaseJson content;
  content.set("fields/name/stringValue", "SMEnergy " + deviceID);
  content.set("fields/source/stringValue", "esp32_pzem");
  content.set("fields/placeholder/booleanValue", false);
  content.set("fields/is_online/booleanValue", true);
  content.set("fields/last_seen/timestampValue", timestampIso);

  patchDocument(
    deviceDocPath(),
    content,
    "name,source,placeholder,is_online,last_seen"
  );
}

void upsertSensorDoc(
  const SensorDef &sensor,
  float watts,
  float voltage,
  float current,
  float energy,
  const String &timestampIso
) {
  FirebaseJson content;
  content.set("fields/name/stringValue", sensor.name);
  content.set("fields/sensor_name/stringValue", sensor.name);
  content.set("fields/source/stringValue", "esp32_pzem");
  content.set("fields/placeholder/booleanValue", false);
  content.set("fields/phase/integerValue", sensor.phase);
  content.set("fields/limit_watts/doubleValue", SENSOR_DEFAULT_LIMIT_WATTS);
  content.set("fields/current_watts/doubleValue", watts);
  content.set("fields/voltage/doubleValue", voltage);
  content.set("fields/current/doubleValue", current);
  content.set("fields/energy/doubleValue", energy);
  content.set("fields/is_online/booleanValue", true);
  content.set("fields/last_reading_at/timestampValue", timestampIso);

  patchDocument(
    sensorDocPath(sensor.id),
    content,
    "name,sensor_name,source,placeholder,phase,limit_watts,current_watts,voltage,current,energy,is_online,last_reading_at"
  );
}

void addReading(
  const SensorDef &sensor,
  float watts,
  float voltage,
  float current,
  float energy,
  const String &timestampIso
) {
  FirebaseJson content;
  content.set("fields/timestamp/timestampValue", timestampIso);
  content.set("fields/watts/doubleValue", watts);
  content.set("fields/source/stringValue", "esp32_pzem");
  content.set("fields/voltage/doubleValue", voltage);
  content.set("fields/current/doubleValue", current);
  content.set("fields/energy/doubleValue", energy);
  content.set("fields/phase/integerValue", sensor.phase);

  String docId = String(sensor.id) + "_" + String((uint32_t)Firebase.getCurrentTime()) + "_" + String(readingCounter++);
  bool ok = Firebase.Firestore.createDocument(
    &fbdo,
    FIREBASE_PROJECT_ID,
    FIRESTORE_DB_ID,
    sensorReadingsCollectionPath(sensor.id).c_str(),
    docId.c_str(),
    content.raw()
  );
  if (!ok) {
    logFirebaseError("createDocument(reading)");
  }
}

void checkRemoteReset() {
  unsigned long nowMs = millis();
  if (nowMs - lastResetCheckMs < RESET_CHECK_INTERVAL_MS) {
    return;
  }
  lastResetCheckMs = nowMs;

  if (!Firebase.Firestore.getDocument(
        &fbdo,
        FIREBASE_PROJECT_ID,
        FIRESTORE_DB_ID,
        deviceDocPath().c_str(),
        "command"
      )) {
    return;
  }

  FirebaseJson payload;
  payload.setJsonData(fbdo.payload());
  FirebaseJsonData cmdData;
  payload.get(cmdData, "fields/command/stringValue");

  if (!cmdData.success || cmdData.stringValue != "reset") {
    return;
  }

  Serial.println("Comando remoto: reset");

  FirebaseJson clearCmd;
  clearCmd.set("fields/command/stringValue", "");
  clearCmd.set("fields/is_online/booleanValue", false);
  patchDocument(deviceDocPath(), clearCmd, "command,is_online");

  clearProvisioning();
  WiFi.disconnect(true, true);
  delay(300);
  ESP.restart();
}

void processProvisioningRequestIfAny() {
  if (!provisioningPending) {
    return;
  }

  provisioningPending = false;
  saveProvisioning(pendingSSID, pendingPassword, pendingOwnerUID);

  bool connected = connectToWifi(configuredSSID, configuredPassword);
  if (connected) {
    initFirebaseIfNeeded();
    Serial.println("Provisioning concluído com sucesso.");
  } else {
    Serial.println("Falha ao ligar ao WiFi após provisioning.");
    setupProvisioningServer();
  }
}

void maintainWiFiConnection() {
  if (configuredSSID.length() == 0) {
    setupProvisioningServer();
    return;
  }

  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  unsigned long nowMs = millis();
  if (nowMs - lastWifiRetryMs < WIFI_RETRY_INTERVAL_MS) {
    return;
  }
  lastWifiRetryMs = nowMs;

  if (!connectToWifi(configuredSSID, configuredPassword)) {
    setupProvisioningServer();
  } else {
    initFirebaseIfNeeded();
  }
}

void readAndPublish(const SensorDef &sensor) {
  float voltage = sensor.pzem->voltage();
  float watts = sensor.pzem->power();
  float current = sensor.pzem->current();
  float energy = sensor.pzem->energy();

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
    return;
  }

  display.setTextSize(2);
  display.print((int)watts);
  display.println(" W");
  display.setTextSize(1);
  display.print(voltage, 1);
  display.print("V | ");
  display.print(current, 2);
  display.println("A");
  display.display();

  if (WiFi.status() != WL_CONNECTED || !Firebase.ready() || ownerUID.length() == 0) {
    return;
  }

  String timestampIso = nowIsoUtc();
  upsertDeviceDoc(timestampIso);
  upsertSensorDoc(sensor, watts, voltage, current, energy, timestampIso);
  addReading(sensor, watts, voltage, current, energy, timestampIso);
}

void setup() {
  Serial.begin(115200);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED Erro");
  }
  display.setTextColor(WHITE);

  Serial2.begin(9600, SERIAL_8N1, 16, 17);

  deviceID = buildDeviceId();
  loadProvisioning();

  bool connected = connectToWifi(configuredSSID, configuredPassword);
  if (connected) {
    initFirebaseIfNeeded();
  } else {
    setupProvisioningServer();
  }
}

void loop() {
  processProvisioningRequestIfAny();
  maintainWiFiConnection();

  for (size_t i = 0; i < (sizeof(sensors) / sizeof(sensors[0])); i++) {
    readAndPublish(sensors[i]);
    delay(SENSOR_LOOP_DELAY_MS);
  }

  if (WiFi.status() == WL_CONNECTED && Firebase.ready() && ownerUID.length() > 0) {
    checkRemoteReset();
  }
}

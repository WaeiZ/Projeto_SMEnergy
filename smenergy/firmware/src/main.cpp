#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <PZEM004Tv30.h>
#include <WiFiManager.h>
#include <FirebaseESP32.h>

// --- CREDENCIAIS ---
#define FIREBASE_HOST "teu-projeto-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "tua-chave-secreta-api"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Instâncias com endereços diferentes no mesmo barramento Serial2 (16, 17)
PZEM004Tv30 pzem1(Serial2, 16, 17, 0x01);
PZEM004Tv30 pzem2(Serial2, 16, 17, 0x02);
PZEM004Tv30 pzem3(Serial2, 16, 17, 0x03);

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
String deviceID;

void setup() {
  Serial.begin(115200);
  
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) Serial.println("OLED Erro");
  display.setTextColor(WHITE);

  // ID único para o Firebase e para o AP
  deviceID = String((uint32_t)ESP.getEfuseMac(), HEX);
  deviceID.toUpperCase();

  WiFiManager wm;
  // O portal abrirá com o nome ESP32_PZEM_XXXX
  if(!wm.autoConnect(("ESP32_PZEM_" + deviceID).c_str())) {
    ESP.restart();
  }

  // Configuração Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Inicializa a Serial2 uma única vez para todos
  Serial2.begin(9600, SERIAL_8N1, 16, 17);
}

void lerEEnviar(PZEM004Tv30& pzem, String sID, int fase) {
  float v = pzem.voltage();
  float p = pzem.power();
  float i = pzem.current();
  float e = pzem.energy();

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0,0);
  display.print("SISTEMA TRIFASICO - F"); display.println(fase);
  display.drawLine(0, 10, 128, 10, WHITE);
  
  display.setCursor(0, 25);
  if (isnan(v)) {
    display.println("ERRO SENSOR " + sID);
  } else {
    display.setTextSize(2);
    display.print((int)p); display.println(" W");
    display.setTextSize(1);
    display.print(v,1); display.print("V | "); display.print(i,2); display.println("A");
    
    if (Firebase.ready()) {
      FirebaseJson json;
      json.add("sensor_id", sID);
      json.add("power", p);
      json.add("voltage", v);
      json.add("energy", e);
      json.add("timestamp", ".sv");
      // Envia para o nó readings/DEVICE_ID
      Firebase.pushJSON(fbdo, "/readings/" + deviceID, json);
    }
  }
  display.display();
}

void loop() {
  lerEEnviar(pzem1, "pzem_01", 1);
  delay(3000);
  lerEEnviar(pzem2, "pzem_02", 2);
  delay(3000);
  lerEEnviar(pzem3, "pzem_03", 3);
  delay(3000);

  // Lógica de reset remoto via App Flutter
  if (Firebase.ready() && Firebase.getString(fbdo, "/devices/" + deviceID + "/command")) {
    if (fbdo.stringData() == "reset") {
      WiFiManager wm;
      wm.resetSettings();
      Firebase.deleteNode(fbdo, "/devices/" + deviceID + "/command");
      ESP.restart();
    }
  }
}
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <PZEM004Tv30.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define TEST_LOOP_DELAY_MS 60000UL
#define SENSOR_PAUSE_MS 250UL

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

PZEM004Tv30 pzem1(Serial2, 16, 17, 0x01);
PZEM004Tv30 pzem2(Serial2, 16, 17, 0x02);
PZEM004Tv30 pzem3(Serial2, 16, 17, 0x03);

struct TestSensor {
  PZEM004Tv30 *pzem;
  const char *id;
  int phase;
};

TestSensor sensors[] = {
  {&pzem1, "sensor_1", 1},
  {&pzem2, "sensor_2", 2},
  {&pzem3, "sensor_3", 3},
};

const size_t SENSOR_COUNT = sizeof(sensors) / sizeof(sensors[0]);
uint32_t cycleNumber = 0;

void showStatus(const String &line1, const String &line2 = "", const String &line3 = "") {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("PZEM SEQ TEST");
  display.drawLine(0, 10, 128, 10, WHITE);
  display.setCursor(0, 18);
  display.println(line1);
  if (line2.length() > 0) display.println(line2);
  if (line3.length() > 0) display.println(line3);
  display.display();
}

bool readSensor(const TestSensor &sensor) {
  unsigned long startMs = millis();

  float voltage = sensor.pzem->voltage();
  float current = sensor.pzem->current();
  float watts = sensor.pzem->power();
  float energy = sensor.pzem->energy();
  unsigned long elapsedMs = millis() - startMs;

  bool ok = !isnan(voltage) && !isnan(current) && !isnan(watts) && !isnan(energy);

  Serial.print(sensor.id);
  Serial.print(" F");
  Serial.print(sensor.phase);
  Serial.print(" ");
  Serial.print(ok ? "OK" : "ERRO");
  Serial.print(" em ");
  Serial.print(elapsedMs);
  Serial.print("ms");

  if (ok) {
    Serial.print(" | ");
    Serial.print(watts, 1);
    Serial.print("W ");
    Serial.print(voltage, 1);
    Serial.print("V ");
    Serial.print(current, 3);
    Serial.print("A ");
    Serial.print(energy, 3);
    Serial.print("kWh");
  }
  Serial.println();

  showStatus(
    String(sensor.id) + (ok ? " OK" : " ERRO"),
    ok ? String(watts, 1) + "W | " + String(voltage, 1) + "V" : "Sem resposta",
    "tempo: " + String(elapsedMs) + "ms"
  );

  return ok;
}

void setup() {
  Serial.begin(115200);
  delay(500);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED Erro");
  }
  display.setTextColor(WHITE);
  showStatus("A iniciar...");

  Serial2.begin(9600, SERIAL_8N1, 16, 17);
  delay(1000);

  Serial.println();
  Serial.println("=== PZEM sequential read test ===");
  Serial.println("Le os sensores 1, 2 e 3 em sequencia e espera 60s no fim.");
  Serial.println("Sem Wi-Fi e sem Firebase, para isolar o barramento PZEM.");
}

void loop() {
  cycleNumber++;
  unsigned long cycleStart = millis();
  bool allOk = true;

  Serial.println();
  Serial.print("Ciclo ");
  Serial.print(cycleNumber);
  Serial.println(" inicio");

  for (size_t i = 0; i < SENSOR_COUNT; i++) {
    if (!readSensor(sensors[i])) {
      allOk = false;
    }
    delay(SENSOR_PAUSE_MS);
  }

  unsigned long cycleElapsed = millis() - cycleStart;
  Serial.print("Ciclo ");
  Serial.print(cycleNumber);
  Serial.print(allOk ? " OK" : " com erros");
  Serial.print(" | duracao leituras: ");
  Serial.print(cycleElapsed);
  Serial.println("ms");

  showStatus(
    allOk ? "Ciclo OK" : "Ciclo com erros",
    "leituras: " + String(cycleElapsed) + "ms",
    "esperar 60s"
  );

  delay(TEST_LOOP_DELAY_MS);
}

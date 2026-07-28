#include <Arduino.h>
#include <NimBLEDevice.h>
#include <string>

// Neuro Cóndor + ANTARA: firmware exclusivo para el modo espejo.
// Use una etapa de potencia adecuada; no conecte motor ni válvulas
// directamente a los GPIO del ESP32.

constexpr uint8_t PIN_MOTOR_PRINCIPAL = 26;
constexpr uint8_t PIN_VALVULA_INFLAR = 18;
constexpr uint8_t PIN_VALVULA_DESINFLAR = 33;
constexpr uint16_t INTERBLOQUEO_MS = 20;

constexpr char DEVICE_NAME[] = "ANTARA";
constexpr char SERVICE_UUID[] = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char MIRROR_RX_UUID[] = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

void apagarSalidas() {
  digitalWrite(PIN_MOTOR_PRINCIPAL, LOW);
  digitalWrite(PIN_VALVULA_INFLAR, LOW);
  digitalWrite(PIN_VALVULA_DESINFLAR, LOW);
}

void paradaSegura() {
  apagarSalidas();
  Serial.println("M,2 -> parada segura");
}

void abrirMano() {
  // M,0: extensión. Primero se desenergizan todas las salidas para evitar
  // activar simultáneamente las dos válvulas.
  apagarSalidas();
  delay(INTERBLOQUEO_MS);
  digitalWrite(PIN_VALVULA_INFLAR, HIGH);
  digitalWrite(PIN_MOTOR_PRINCIPAL, HIGH);
  Serial.println("M,0 -> mano abierta / inflando");
}

void cerrarMano() {
  // M,1: flexión.
  apagarSalidas();
  delay(INTERBLOQUEO_MS);
  digitalWrite(PIN_VALVULA_DESINFLAR, HIGH);
  digitalWrite(PIN_MOTOR_PRINCIPAL, HIGH);
  Serial.println("M,1 -> mano cerrada / desinflando");
}

bool procesarComandoEspejo(String comando) {
  comando.trim();

  if (comando == "M,0") {
    abrirMano();
    return true;
  }
  if (comando == "M,1") {
    cerrarMano();
    return true;
  }
  if (comando == "M,2") {
    paradaSegura();
    return true;
  }

  Serial.print("Comando rechazado: ");
  Serial.println(comando);
  return false;
}

class AntaraServerCallbacks final : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer *, NimBLEConnInfo &) override {
    Serial.println("BLE: ANTARA conectado");
  }

  void onDisconnect(
      NimBLEServer *,
      NimBLEConnInfo &,
      int reason) override {
    paradaSegura();
    Serial.print("BLE: desconectado. Motivo: ");
    Serial.println(reason);
    NimBLEDevice::startAdvertising();
  }
};

class AntaraRxCallbacks final : public NimBLECharacteristicCallbacks {
  void onWrite(
      NimBLECharacteristic *characteristic,
      NimBLEConnInfo &) override {
    const std::string value = characteristic->getValue();
    if (value.empty()) return;
    procesarComandoEspejo(String(value.c_str()));
  }
};

void iniciarBluetooth() {
  NimBLEDevice::init(DEVICE_NAME);

  NimBLEServer *server = NimBLEDevice::createServer();
  server->setCallbacks(new AntaraServerCallbacks());

  NimBLEService *service = server->createService(SERVICE_UUID);
  NimBLECharacteristic *mirrorRx = service->createCharacteristic(
      MIRROR_RX_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  mirrorRx->setCallbacks(new AntaraRxCallbacks());
  service->start();

  NimBLEAdvertising *advertising = NimBLEDevice::getAdvertising();
  advertising->setName(DEVICE_NAME);
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->enableScanResponse(true);
  advertising->start();

  Serial.println("ANTARA listo: modo espejo M,0 / M,1 / M,2");
}

void setup() {
  Serial.begin(115200);

  pinMode(PIN_MOTOR_PRINCIPAL, OUTPUT);
  pinMode(PIN_VALVULA_INFLAR, OUTPUT);
  pinMode(PIN_VALVULA_DESINFLAR, OUTPUT);
  paradaSegura();

  iniciarBluetooth();
}

void loop() {
  // El control es asíncrono mediante los callbacks BLE.
  delay(20);
}

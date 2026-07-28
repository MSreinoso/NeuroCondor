#include <Arduino.h>
#include <NimBLEDevice.h>
#include <string>

// Neuro Cóndor + ANTARA: firmware exclusivo para el modo espejo.
// Use una etapa de potencia adecuada; no conecte motor ni válvulas
// directamente a los GPIO del ESP32.

constexpr uint8_t PIN_MOTOR_PRINCIPAL = 27;
constexpr uint8_t PIN_VALVULA_INFLAR = 25;
constexpr uint8_t PIN_VALVULA_DESINFLAR = 32;
constexpr uint8_t PIN_CONTROL = 35;
constexpr uint16_t INTERBLOQUEO_MS = 20;
constexpr uint16_t ANTIRREBOTE_MS = 35;

constexpr char DEVICE_NAME[] = "ANTARA";
constexpr char SERVICE_UUID[] = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char MIRROR_RX_UUID[] = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char MIRROR_TX_UUID[] = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

NimBLECharacteristic *mirrorTx = nullptr;
bool antaraConnected = false;
bool ultimoControlCrudo = false;
bool controlEstable = false;
uint32_t controlCambioEnMs = 0;

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
  // Control 1: extensión. Primero se desenergizan todas las salidas para evitar
  // activar simultáneamente las dos válvulas.
  apagarSalidas();
  delay(INTERBLOQUEO_MS);
  digitalWrite(PIN_VALVULA_INFLAR, HIGH);
  digitalWrite(PIN_MOTOR_PRINCIPAL, HIGH);
  Serial.println("Control 1 -> mano abierta / inflando");
}

void cerrarMano() {
  // Control 0: flexión.
  apagarSalidas();
  delay(INTERBLOQUEO_MS);
  digitalWrite(PIN_VALVULA_DESINFLAR, HIGH);
  digitalWrite(PIN_MOTOR_PRINCIPAL, HIGH);
  Serial.println("Control 0 -> mano cerrada / desinflando");
}

void notificarControl() {
  if (mirrorTx == nullptr) return;
  mirrorTx->setValue(controlEstable ? "1\n" : "0\n");
  if (antaraConnected) mirrorTx->notify();
}

void aplicarControl() {
  if (!antaraConnected) return;

  if (controlEstable) {
    abrirMano();
  } else {
    cerrarMano();
  }
  notificarControl();
}

void actualizarControl() {
  const bool controlCrudo = digitalRead(PIN_CONTROL) == HIGH;
  if (controlCrudo != ultimoControlCrudo) {
    ultimoControlCrudo = controlCrudo;
    controlCambioEnMs = millis();
  }

  if (controlCrudo != controlEstable &&
      millis() - controlCambioEnMs >= ANTIRREBOTE_MS) {
    controlEstable = controlCrudo;
    aplicarControl();
  }
}

bool procesarComando(String comando) {
  comando.trim();

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
    antaraConnected = true;
    Serial.println("BLE: ANTARA conectado");
    aplicarControl();
  }

  void onDisconnect(
      NimBLEServer *,
      NimBLEConnInfo &,
      int reason) override {
    antaraConnected = false;
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
    procesarComando(String(value.c_str()));
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

  mirrorTx = service->createCharacteristic(
      MIRROR_TX_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  notificarControl();
  service->start();

  NimBLEAdvertising *advertising = NimBLEDevice::getAdvertising();
  advertising->setName(DEVICE_NAME);
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->enableScanResponse(true);
  advertising->start();

  Serial.println("ANTARA listo: GPIO 35 controla 1=abrir y 0=cerrar");
}

void setup() {
  Serial.begin(115200);

  pinMode(PIN_MOTOR_PRINCIPAL, OUTPUT);
  pinMode(PIN_VALVULA_INFLAR, OUTPUT);
  pinMode(PIN_VALVULA_DESINFLAR, OUTPUT);
  // GPIO 35 no dispone de resistencia pull-up/pull-down interna.
  // La señal de control debe tener un nivel definido por el circuito externo.
  pinMode(PIN_CONTROL, INPUT);
  paradaSegura();

  ultimoControlCrudo = digitalRead(PIN_CONTROL) == HIGH;
  controlEstable = ultimoControlCrudo;
  controlCambioEnMs = millis();
  iniciarBluetooth();
}

void loop() {
  actualizarControl();
  delay(5);
}

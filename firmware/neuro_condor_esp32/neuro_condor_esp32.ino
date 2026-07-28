#include <Arduino.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Adapte los pines a la tarjeta y use una etapa de potencia aislada.
constexpr uint8_t CONTROL_INPUT_PIN = 32; // HIGH carga/abre; LOW salta/cierra.
constexpr uint8_t GLOVE_VALVE_PIN = 25;   // Salida hacia driver, MOSFET o relé.
constexpr uint8_t ESTOP_PIN = 33;         // Parada de emergencia activa en LOW.
constexpr uint8_t GLOVE_OPEN_LEVEL = HIGH;
constexpr uint8_t GLOVE_CLOSE_LEVEL = LOW;

constexpr uint32_t PHASE_MS = 5000;
constexpr uint32_t INPUT_DEBOUNCE_MS = 150;
constexpr char SERVICE_UUID[] = "7d9b0001-8e7f-4b7f-a8d1-3a6b5c2d1000";
constexpr char NOTIFY_UUID[] = "7d9b0002-8e7f-4b7f-a8d1-3a6b5c2d1000";
constexpr char COMMAND_UUID[] = "7d9b0003-8e7f-4b7f-a8d1-3a6b5c2d1000";

enum class GlovePhase : uint8_t {
  idleClosed,
  opening,
  holdOpen,
  readyOpen,
  closing,
  holdClosed,
};

BLECharacteristic *notifyCharacteristic = nullptr;
GlovePhase phase = GlovePhase::idleClosed;
uint32_t phaseStartedAt = 0;
uint32_t lastCountdownAt = 0;
bool connected = false;
bool lastRawPinActive = false;
bool stablePinActive = false;
uint32_t rawPinChangedAt = 0;
bool cycleAccepted = false;
bool closeRequested = false;

void notifyLine(const String &message) {
  if (!connected || notifyCharacteristic == nullptr) return;
  const String framed = message + "\n";
  notifyCharacteristic->setValue(framed.c_str());
  notifyCharacteristic->notify();
}

const char *phaseName(GlovePhase value) {
  switch (value) {
    case GlovePhase::opening: return "OPENING";
    case GlovePhase::holdOpen: return "OPEN";
    case GlovePhase::readyOpen: return "OPEN_READY";
    case GlovePhase::closing: return "CLOSING";
    case GlovePhase::holdClosed: return "CLOSED_WAIT";
    default: return "IDLE";
  }
}

void applySafeClosed() {
  digitalWrite(GLOVE_VALVE_PIN, GLOVE_CLOSE_LEVEL);
  phase = GlovePhase::idleClosed;
  cycleAccepted = false;
  closeRequested = false;
}

void setPhase(GlovePhase next) {
  phase = next;
  phaseStartedAt = millis();
  lastCountdownAt = 0;
  digitalWrite(GLOVE_VALVE_PIN,
               (next == GlovePhase::opening ||
                next == GlovePhase::holdOpen ||
                next == GlovePhase::readyOpen)
                   ? GLOVE_OPEN_LEVEL
                   : GLOVE_CLOSE_LEVEL);
  const uint8_t seconds = next == GlovePhase::readyOpen ? 0 : 5;
  notifyLine(String("G,") + phaseName(next) + "," + seconds);
}

void acceptPinActivation() {
  if (digitalRead(ESTOP_PIN) == LOW) {
    notifyLine("E,ESTOP_ACTIVE");
    return;
  }
  if (phase != GlovePhase::idleClosed || cycleAccepted) {
    notifyLine("E,CYCLE_LOCKED");
    return;
  }
  cycleAccepted = true;
  closeRequested = false;
  notifyLine("P,1");
  setPhase(GlovePhase::opening);
}

void acceptPinDeactivation() {
  if (!cycleAccepted || closeRequested) return;
  closeRequested = true;
  notifyLine("P,0");
  if (phase == GlovePhase::readyOpen) setPhase(GlovePhase::closing);
}

void onStablePinChanged(bool active) {
  if (active) {
    acceptPinActivation();
  } else {
    acceptPinDeactivation();
  }
}

void updateDigitalInput() {
  const bool rawActive = digitalRead(CONTROL_INPUT_PIN) == HIGH;
  if (rawActive != lastRawPinActive) {
    lastRawPinActive = rawActive;
    rawPinChangedAt = millis();
  }
  if (rawActive != stablePinActive &&
      millis() - rawPinChangedAt >= INPUT_DEBOUNCE_MS) {
    stablePinActive = rawActive;
    onStablePinChanged(stablePinActive);
  }
}

void updateGlove() {
  if (digitalRead(ESTOP_PIN) == LOW) {
    if (phase != GlovePhase::idleClosed) notifyLine("E,ESTOP_ACTIVE");
    applySafeClosed();
    return;
  }
  if (phase == GlovePhase::idleClosed || phase == GlovePhase::readyOpen) return;

  const uint32_t elapsed = millis() - phaseStartedAt;
  if (millis() - lastCountdownAt >= 1000) {
    lastCountdownAt = millis();
    const uint8_t remaining =
        elapsed >= PHASE_MS ? 0 : (PHASE_MS - elapsed + 999) / 1000;
    notifyLine(String("G,") + phaseName(phase) + "," + remaining);
  }
  if (elapsed < PHASE_MS) return;

  switch (phase) {
    case GlovePhase::opening:
      setPhase(GlovePhase::holdOpen);
      break;
    case GlovePhase::holdOpen:
      setPhase(closeRequested ? GlovePhase::closing : GlovePhase::readyOpen);
      break;
    case GlovePhase::closing:
      setPhase(GlovePhase::holdClosed);
      break;
    case GlovePhase::holdClosed:
      applySafeClosed();
      notifyLine("G,IDLE,0");
      break;
    default:
      break;
  }
}

class ServerCallbacks final : public BLEServerCallbacks {
  void onConnect(BLEServer *) override { connected = true; }
  void onDisconnect(BLEServer *server) override {
    connected = false;
    applySafeClosed();
    delay(50);
    server->getAdvertising()->start();
  }
};

class CommandCallbacks final : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    const String command(characteristic->getValue().c_str());
    if (command.startsWith("C,STOP")) {
      applySafeClosed();
      notifyLine("G,IDLE,0");
    } else {
      notifyLine("E,UNKNOWN_COMMAND");
    }
  }
};

void setup() {
  pinMode(CONTROL_INPUT_PIN, INPUT_PULLDOWN);
  pinMode(ESTOP_PIN, INPUT_PULLUP);
  pinMode(GLOVE_VALVE_PIN, OUTPUT);
  applySafeClosed();

  BLEDevice::init("NeuroCondor-ESP32");
  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService *service = server->createService(SERVICE_UUID);
  notifyCharacteristic = service->createCharacteristic(
      NOTIFY_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  notifyCharacteristic->addDescriptor(new BLE2902());
  BLECharacteristic *command = service->createCharacteristic(
      COMMAND_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  command->setCallbacks(new CommandCallbacks());
  service->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->start();
}

void loop() {
  updateDigitalInput();
  updateGlove();
  delay(5);
}

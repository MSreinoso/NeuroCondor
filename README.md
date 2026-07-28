# Neuro Cóndor

Juego de rehabilitación neurológica para Android y web que controla el guante
ANTARA por Bluetooth Low Energy. Esta edición utiliza exclusivamente el
**modo espejo**: abrir, cerrar y detener.

## Incluye

- registro y progreso local, sin servidor ni cuenta externa;
- tutorial y 9 niveles progresivos;
- economía con monedas, tienda y 8 aves representativas del Ecuador;
- personajes vectoriales con anatomía y marcas propias de cada especie;
- vuelo animado con aleteo, inclinación, estelas y aterrizaje;
- interfaz responsiva comprobada desde 320 px de ancho;
- conexión BLE directa con el dispositivo `ANTARA`;
- lectura de la entrada física GPIO 35 y envío de sus estados por BLE;
- parada segura al desconectar Bluetooth o salir de una partida.

No contiene modo automático, estimulación vibratoria ni modo de demostración.

## Ejecutar y compilar

Requisitos: Flutter 3.24 o posterior y Android SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

La aplicación web se publica automáticamente con GitHub Pages desde `main`.
En PC y Android debe abrirse con Chrome o Edge mediante HTTPS. En iPhone se
requiere un navegador que implemente Web Bluetooth, como Bluefy.

## Uso

1. Cargar en el ESP32
   `firmware/neuro_condor_esp32/neuro_condor_esp32.ino`.
2. Encender el controlador ANTARA y abrir Neuro Cóndor.
3. Abrir el menú Bluetooth y pulsar **Buscar ANTARA**.
4. Conectar el dispositivo encontrado.
5. Poner GPIO 35 en `1`: el guante abre y la app carga el vuelo.
6. Poner GPIO 35 en `0`: el guante cierra y el ave salta.

## Protocolo BLE ANTARA

Nombre anunciado: `ANTARA`

| Elemento | UUID | Uso |
|---|---|---|
| Servicio | `6e400001-b5a3-f393-e0a9-e50e24dcca9e` | Servicio exclusivo de modo espejo |
| RX | `6e400002-b5a3-f393-e0a9-e50e24dcca9e` | App → ESP32, parada segura |
| TX | `6e400003-b5a3-f393-e0a9-e50e24dcca9e` | ESP32 → app, estado GPIO 35 mediante read/notify |

Eventos ASCII enviados por el ESP32:

| Evento | Guante | Juego |
|---|---|---|
| `1` | abre e infla | carga el salto |
| `0` | cierra y desinfla | libera el salto |

La app únicamente puede enviar `M,2` para ejecutar la parada segura. Cada
mensaje termina en salto de línea.

## Pines del ESP32

| GPIO | Función |
|---|---|
| 27 | motor principal |
| 25 | válvula de inflado |
| 32 | válvula de desinflado |
| 35 | entrada de control: `1` abre/carga; `0` cierra/salta |

Antes de cambiar entre inflado y desinflado, el firmware apaga todas las
salidas durante 20 ms para impedir que las dos válvulas se activen a la vez.
La entrada aplica 35 ms de antirrebote. GPIO 35 no tiene resistencia pull-up o
pull-down interna: el circuito debe entregarle siempre un nivel definido de
3.3 V o 0 V. Al perder BLE, motor y válvulas quedan en `LOW`.

El firmware usa `NimBLEDevice.h` y las firmas de callback de NimBLE-Arduino
2.x. Instale esa biblioteca desde el gestor de bibliotecas de Arduino IDE.

## Arquitectura

```text
lib/
├── ble/       protocolo espejo y conexión ANTARA
├── data/      perfil, economía, inventario y tiempos
├── game/      motor, física y renderizado de aves
├── models/    niveles, personajes y usuario
├── screens/   registro, inicio, ruta, tienda, ANTARA y partida
└── widgets/   componentes compartidos
firmware/
└── neuro_condor_esp32/neuro_condor_esp32.ino
test/
```

## Seguridad

No conecte motores o electroválvulas directamente al ESP32. Utilice una etapa
de potencia apropiada, MOSFET o relé, diodo de rueda libre cuando corresponda,
fuente separada, regulación de presión, límites mecánicos y una parada física
que no dependa de Bluetooth.

Este repositorio es una base de ingeniería y no un dispositivo médico
certificado. Antes de utilizarlo con pacientes deben validarse presión, fuerza,
recorrido, tiempos terapéuticos, pérdida de alimentación y pérdida de BLE con
el equipo clínico.

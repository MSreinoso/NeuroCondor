# Neuro Cóndor

Base funcional de un juego móvil offline de rehabilitación neurológica para Android e iOS. La interacción de juego no usa toques, cámaras ni visión artificial: el ESP32 lee un pin digital y transmite sus cambios a la app por BLE.

## Incluye

- registro local del participante, sin servidor ni cuenta externa;
- tutorial obligatorio y 9 niveles progresivos;
- economía local con recompensas por nivel, saldo visible y compras con monedas;
- tienda con inventario persistente, requisitos de progreso y selección de avatar;
- 8 aves representativas de la Sierra, Costa, Amazonía y Galápagos;
- personajes vectoriales con anatomía, silueta y marcas reales propias de cada
  especie ecuatoriana;
- vuelo animado con aleteo, inclinación, estelas y reacción al aterrizaje;
- interfaz responsiva comprobada desde 320 px de ancho, sin tarjetas, botones
  ni pestañas superpuestas;
- 3 niveles fáciles con plataformas, 3 medios con espinas y 3 difíciles con espinas y plataformas móviles;
- cronómetro por partida y mejor tiempo local por nivel;
- motor 2D propio con carga, salto, gravedad, aterrizaje y colisiones;
- conexión BLE real y modo demostración para probar sin hardware;
- ciclo neumático no bloqueante con cuatro fases mecánicas de 5 s ejecutado por el ESP32;
- parada de emergencia, estado seguro al desconectar y rechazo de ciclos simultáneos;
- pruebas unitarias de mecánica, protocolo y composición de niveles.

## Ejecutar la app

Requisitos: Flutter 3.24 o posterior, Android SDK y, para iOS, macOS con Xcode y CocoaPods.

```bash
flutter pub get
flutter test
flutter run
```

## Versión web con Bluetooth

La aplicación web se publica automáticamente con GitHub Pages desde la rama
`main`. El mismo HTML funciona en PC, Android y iPhone.

- En Windows, macOS, Linux, ChromeOS y Android: abrir la dirección HTTPS con
  Chrome o Edge y seleccionar **Buscar ESP32**.
- En iPhone o iPad: Chrome y Safari no ofrecen Web Bluetooth. Instalar
  [Bluefy](https://apps.apple.com/app/bluefy-web-ble-browser/id1492822055),
  abrir allí la dirección HTTPS y seleccionar **Buscar ESP32**.

La aplicación comprueba la capacidad real del navegador, en lugar de bloquear
Bluetooth por el tipo de dispositivo. Esto permite usar navegadores iOS que
implementan Web Bluetooth.

Al publicar una etiqueta con formato `v*`, GitHub Actions genera una versión
descargable con el APK Android y el paquete web para iPhone.

En iOS, abra `ios/Runner.xcworkspace` después de `pod install` si necesita configurar el equipo de firma. En Android, configure una clave de firma propia antes de publicar; el perfil `release` conserva la firma de depuración solo para facilitar el prototipo.

La primera vez, abra el icono Bluetooth y conecte `NeuroCondor-ESP32`. La
selección del dispositivo debe iniciarse con una pulsación del usuario y la
página debe usar HTTPS. Para desarrollo puede seleccionar **Usar modo
demostración** y simular los estados 1 y 0 desde la pantalla del nivel. Esos
botones existen solo como herramienta técnica: la ruta clínica usa
exclusivamente el pin físico y BLE.

## Arquitectura

```text
lib/
├── ble/       protocolo, escaneo, conexión, notificaciones y comandos
├── data/      perfil, economía, inventario y tiempos con SharedPreferences
├── game/      motor, física y renderizado de personajes
├── models/    niveles, plataformas, personajes y usuario
├── screens/   registro, inicio, ruta, tienda, BLE y partida
└── widgets/   utilidades compartidas
firmware/
└── neuro_condor_esp32/neuro_condor_esp32.ino
test/
```

La app no contiene lógica de temporización crítica del actuador. El ESP32 ejecuta y bloquea las fases mecánicas aunque el teléfono se ralentice; la app únicamente interpreta `P,1` como carga y `P,0` como salto.

## Protocolo BLE

Servicio: `7d9b0001-8e7f-4b7f-a8d1-3a6b5c2d1000`

| Característica | UUID | Dirección |
|---|---|---|
| Eventos | `7d9b0002-8e7f-4b7f-a8d1-3a6b5c2d1000` | ESP32 → app, notify/read |
| Comandos | `7d9b0003-8e7f-4b7f-a8d1-3a6b5c2d1000` | app → ESP32, write |

Mensajes ASCII terminados en salto de línea:

| Mensaje | Significado |
|---|---|
| `P,1` | pin activado; comienza la carga y la apertura del guante |
| `P,0` | pin desactivado; libera la carga, salta y solicita el cierre |
| `C,STOP` | lleva el actuador al estado cerrado seguro |
| `G,OPENING,5` | apertura; cuenta regresiva en segundos |
| `G,OPEN,5` | espera con el guante abierto |
| `G,OPEN_READY,0` | espera abierta completa; aguarda el estado 0 |
| `G,CLOSING,5` | cierre |
| `G,CLOSED_WAIT,5` | espera con el guante cerrado |
| `G,IDLE,0` | ciclo completo, listo |
| `E,<código>` | condición de fallo o comando rechazado |

## Integración del pin digital y el ESP32

El sketch usa por defecto:

- GPIO 32: entrada de control (`HIGH`/1 = cargar y abrir, `LOW`/0 = saltar y cerrar);
- GPIO 25: orden digital hacia la etapa de potencia (`HIGH` = abrir, `LOW` = cerrar);
- GPIO 33: parada de emergencia activa en `LOW`.

No se utiliza cámara ni procesamiento de imagen. El firmware aplica 150 ms de antirrebote al GPIO 32 para evitar saltos dobles. Si el controlador neumático utiliza lógica inversa, intercambie `GLOVE_OPEN_LEVEL` y `GLOVE_CLOSE_LEVEL`.

El ciclo implementado es exacto por máquina de estados basada en `millis()`:

1. al aceptar el estado 1, abrir durante 5 s;
2. mantener la espera abierta obligatoria durante 5 s;
3. al recibir o tener pendiente el estado 0, cerrar durante 5 s;
4. esperar cerrado durante 5 s antes de habilitar otro flanco 1.

Si el pin baja durante la apertura o la espera abierta, el evento `P,0` se envía inmediatamente para ejecutar el salto, pero el cierre físico queda en cola hasta completar los primeros 10 segundos. Un nuevo estado 1 durante el cierre o la espera cerrada se rechaza; después de `G,IDLE,0` se exige un nuevo flanco 0→1.

No conecte una electroválvula directamente al ESP32. Use driver/MOSFET o relé adecuado, aislamiento, diodo de rueda libre cuando corresponda, regulación de presión, límite mecánico y parada de emergencia física.

## Criterios de seguridad y validación

Este repositorio es una base de ingeniería, no un dispositivo médico certificado. Antes de usarlo con pacientes deben validarse presión, fuerza, recorrido, estabilidad eléctrica del pin, pérdida de BLE, fatiga, tiempos terapéuticos y accesibilidad con el equipo clínico. La parada física no debe depender de la app ni del enlace BLE.

Para producción conviene añadir autenticación/emparejamiento BLE, telemetría local de fallos, pruebas con el actuador real y una calibración por participante de la curva potencia-distancia. No se debe cambiar la temporización del guante desde la interfaz de juego.

# Compilar e instalar Neuro Cóndor en iPhone

La versión actual es **0.4.0+4**, usa el identificador
`com.neurocondor.neuroCondor` y requiere iOS 13 o posterior.

Apple exige macOS, Xcode y firma de código para generar e instalar una app
de iPhone. El equivalente del APK de Android es un archivo `.ipa`.

## Requisitos

- Un Mac con la versión actual de Xcode.
- Flutter y CocoaPods instalados.
- Un Apple ID. Una cuenta personal gratuita permite probar en un iPhone
  propio; TestFlight y App Store requieren Apple Developer Program.
- El iPhone conectado por USB durante la configuración inicial.

## Preparar el proyecto en el Mac

Desde la carpeta `neuro_condor`:

```bash
flutter doctor
flutter pub get
cd ios
pod install
cd ..
open ios/Runner.xcworkspace
```

En Xcode:

1. Seleccionar **Runner** y después el target **Runner**.
2. Abrir **Signing & Capabilities**.
3. Activar **Automatically manage signing**.
4. Seleccionar el equipo asociado a la cuenta de Apple.
5. Si `com.neurocondor.neuroCondor` no pertenece a esa cuenta, cambiar
   **Bundle Identifier** por uno único, por ejemplo
   `ec.tuorganizacion.neurocondor`.

## Instalación directa en un iPhone

1. Conectar y desbloquear el iPhone; aceptar **Confiar en este ordenador**.
2. En el iPhone abrir **Ajustes > Privacidad y seguridad > Modo de
   desarrollador**, activarlo y reiniciar el dispositivo.
3. En Xcode seleccionar el iPhone como destino de ejecución.
4. Presionar **Run**. Xcode compila, firma e instala la aplicación.
5. Si iOS lo solicita, abrir **Ajustes > General > VPN y gestión de
   dispositivos** y confiar en el certificado del desarrollador.

Con una cuenta personal gratuita, la firma de desarrollo tiene limitaciones
y puede ser necesario volver a instalar la app periódicamente.

## Generar el archivo IPA

Después de configurar la firma:

```bash
flutter build ipa --release
```

El resultado se crea en:

```text
build/ios/ipa/
```

Para una instalación controlada fuera de TestFlight, se puede usar un método
de exportación acorde al perfil de aprovisionamiento:

```bash
flutter build ipa --release --export-method development
```

El iPhone debe estar incluido en el perfil correspondiente. Las instalaciones
locales de un `.ipa` requieren Modo de desarrollador y una firma válida.

## Distribución recomendada con TestFlight

1. Crear la aplicación y registrar su Bundle ID en App Store Connect.
2. En Xcode ejecutar **Product > Archive**.
3. En Organizer seleccionar **Distribute App > App Store Connect > Upload**.
4. Esperar el procesamiento del build en la pestaña **TestFlight**.
5. Crear un grupo de pruebas y agregar usuarios.
6. Cada usuario instala **TestFlight** desde App Store, acepta la invitación
   y pulsa **Instalar**.

TestFlight evita registrar manualmente cada iPhone y es la opción recomendada
para entregar la aplicación a pacientes, terapeutas o evaluadores antes de
publicarla.

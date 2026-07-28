# Instalar Neuro Cóndor HTML en iPhone

Esta edición funciona como una aplicación web instalable. No necesita Mac,
Xcode ni una cuenta de Apple.

## Publicar la carpeta

El contenido de `build/web` debe subirse completo a un alojamiento web con
HTTPS. No se debe abrir `index.html` directamente desde la aplicación Archivos:
Flutter necesita servir sus archivos JavaScript, recursos y caché desde una
dirección web.

Se puede utilizar cualquier alojamiento estático con HTTPS. Al subir la
carpeta, `index.html` debe quedar en la raíz de la dirección publicada.

## Instalar desde Safari

1. Abrir en **Safari** la dirección HTTPS donde se publicó la aplicación.
2. Tocar el botón **Compartir**.
3. Seleccionar **Agregar a pantalla de inicio**.
4. Confirmar el nombre **Neuro Cóndor** y tocar **Agregar**.
5. Abrir el nuevo ícono desde la pantalla de inicio.

El perfil, las monedas, los personajes y los mejores tiempos se guardan
localmente en el navegador del iPhone. Borrar los datos de Safari o del sitio
elimina este progreso.

## Bluetooth en iPhone

Safari para iPhone no implementa Web Bluetooth. La edición HTML activa
automáticamente el modo demostración y muestra los controles **Simular pin 1**
y **Simular pin 0** durante la partida.

La conexión directa con el ESP32 continúa disponible en:

- la aplicación Android;
- la aplicación iOS nativa compilada con Xcode;
- navegadores compatibles con Web Bluetooth, como Chrome o Edge en plataformas
  que exponen esa función.

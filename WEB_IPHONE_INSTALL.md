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

## Instalar como acceso directo

1. Abrir en **Safari** la dirección HTTPS donde se publicó la aplicación.
2. Tocar el botón **Compartir**.
3. Seleccionar **Agregar a pantalla de inicio**.
4. Confirmar el nombre **Neuro Cóndor** y tocar **Agregar**.
5. Abrir el nuevo ícono desde la pantalla de inicio.

El perfil, las monedas, los personajes y los mejores tiempos se guardan
localmente en el navegador del iPhone. Borrar los datos de Safari o del sitio
elimina este progreso.

## Bluetooth en iPhone

Chrome y Safari para iPhone no implementan Web Bluetooth. Para conectar el
ESP32 desde el mismo HTML:

1. instalar
   [Bluefy](https://apps.apple.com/app/bluefy-web-ble-browser/id1492822055);
2. activar Bluetooth en el iPhone y encender `ANTARA`;
3. abrir en Bluefy la dirección HTTPS publicada;
4. tocar el icono Bluetooth, **Buscar ANTARA** y aceptar el permiso.

La aplicación comprueba si el navegador expone Web Bluetooth. Sin esa función
no es posible utilizar el modo espejo.

## Bluetooth en PC y Android

Abrir la misma dirección HTTPS en Chrome o Edge, activar Bluetooth y pulsar
**Buscar ANTARA**. Chrome admite la conexión desde páginas web en computadoras
y Android. El navegador solicitará seleccionar y autorizar el dispositivo.

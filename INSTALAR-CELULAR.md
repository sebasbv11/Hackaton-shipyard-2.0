# Instalar en celular — Manta: Travesía por Jocay

## Opción 1: Probar rápido en el teléfono (sin compilar)

1. En la PC, abre una terminal en la carpeta `manta-juego`.
2. Ejecuta un servidor local:

```bash
npx --yes serve . -p 3456
```

3. Conecta el celular a la **misma red Wi‑Fi** que la PC.
4. En el navegador del celular (Chrome), abre la dirección que muestra el servidor, por ejemplo:
   `http://192.168.1.10:3456`
5. En Android: menú ⋮ → **Añadir a pantalla de inicio** para usarlo como app.

## Opción 2: Generar APK (app Android instalable)

### Requisitos

- [Node.js](https://nodejs.org/) 18 o superior
- [Android Studio](https://developer.android.com/studio) con Android SDK
- Variable de entorno `ANDROID_HOME` configurada

### Pasos

```bash
cd manta-juego
npm install
npx cap add android
npx cap sync android
npx cap open android
```

En Android Studio:

1. Espera a que Gradle termine de sincronizar.
2. Conecta tu celular con **depuración USB** activada, o usa un emulador.
3. Pulsa **Run** (▶) para instalar la app en el dispositivo.

El APK de depuración queda en:

`android/app/build/outputs/apk/debug/app-debug.apk`

Puedes copiar ese archivo al celular e instalarlo manualmente.

## Controles en el celular

- **Joystick** (esquina inferior izquierda): mueve la balsa.
- Antes de cada nivel, lee las instrucciones del guardián cultural y pulsa **Comenzar nivel**.

## Nota sobre iconos

Si faltan `icons/icon-192.png` e `icons/icon-512.png`, la app funciona igual. Para publicar en Play Store, añade iconos PNG de esos tamaños en la carpeta `icons/`.

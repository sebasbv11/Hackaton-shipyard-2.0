# Manta Plataforma Movil (Godot 4.6)

Juego 2D en **orientacion horizontal (landscape)** para movil, escritorio y exportacion Android.

## Probar en Godot

1. Abre Godot 4.6.
2. Importa esta carpeta: `Hackaton-shipyard-2.0`.
3. Abre `project.godot`.
4. Presiona **F5** (Play).
5. En el editor puedes rotar la ventana de juego a modo horizontal (1280x720).

### Controles en juego

| Zona | Accion |
|------|--------|
| **Joystick** (esquina inferior izquierda) | Caminar izquierda / derecha |
| **^ Saltar** (esquina inferior derecha) | Saltar |
| **OK** (lobby, derecha) | Interactuar con barcos |
| **SALTAR** (Flappy, derecha) | Impulso / aleteo |
| Teclado | Flechas o A/D + Espacio |

### Movil en vertical

Si instalas o exportas a Android/iOS y sostienes el telefono en vertical, aparece la pantalla **"Gira tu dispositivo"** (autoload `OrientacionLandscape`) hasta que gires a horizontal.

## Configuracion landscape aplicada

- Resolucion base: **1280x720**.
- Orientacion: **landscape** (`window/handheld/orientation=0`).
- Stretch: `canvas_items` con aspecto `expand`.
- Controles tactiles: `escenas/controles_moviles/` (joystick + botones en esquinas).
- Overlay de rotacion: `scripts/orientacion_landscape.gd` (autoload).

## Exportar a Android

1. En Godot: `Editor > Editor Settings > Export > Android` (SDK, JDK, build tools).
2. `Project > Export` → preset **Android**.
3. En el preset Android, pestana **Screen**:
   - Orientacion: **Landscape** o **Sensor Landscape**.
4. Exporta `.apk` (prueba) o `.aab` (publicacion).

Si Godot pide plantillas: `Editor > Manage Export Templates`.

## Version web (opcional)

La carpeta tambien incluye `index.html` + `js/` como PWA landscape independiente. No se ejecuta dentro de Godot; sirve para probar en navegador con `npx serve .`.

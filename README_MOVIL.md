# Manta Plataforma Movil

Proyecto Godot 4.6 preparado como juego 2D movil en formato vertical.

## Probar en Godot

1. Abre Godot 4.6.
2. Importa esta carpeta: `Hackaton-shipyard-2.0`.
3. Abre `project.godot`.
4. Presiona `F5` o el boton de Play.
5. En la escena principal veras controles tactiles:
   - Boton izquierdo: caminar a la izquierda.
   - Boton derecho: caminar a la derecha.
   - Boton superior derecho: saltar.

## Configuracion movil aplicada

- Resolucion base: `720x1280`.
- Orientacion: vertical.
- Stretch: `canvas_items` con aspecto `expand`.
- Controles tactiles en `escenas/controles_moviles/`.
- Menu sin boton de salida visible, porque en movil se usa el boton del sistema.
- Builds de Windows eliminados.

## Exportar a Android

1. En Godot ve a `Editor > Editor Settings > Export > Android`.
2. Configura Android SDK, JDK y build tools.
3. Ve a `Project > Export`.
4. Agrega un preset `Android`.
5. Exporta como `.apk` para prueba o `.aab` para publicacion.

Si Godot pide export templates, instalalos desde:
`Editor > Manage Export Templates`.

# Manta: El Astillero

Juego movil en Godot 4.6 basado en Manta, Ecuador.

El jugador inicia en el muelle, explora libremente, sube a barcos y completa 4 minijuegos relacionados con la ciudad: pesca, playa, cultura mantena, barcos y astilleros. Al reunir las 4 piezas culturales, vuelve a **EL ASTILLERO** para activar el evento final: la zarpada del Barco Jocay.

## Estado actual

Este repositorio ahora prioriza Godot. La version web/Capacitor fue eliminada para evitar duplicacion, choques de flujo y archivos que ya no representan el objetivo del proyecto.

## Estructura

- `project.godot`: configuracion del proyecto.
- `scenes/hub/`: escena principal del muelle de Manta.
- `scenes/minigames/`: escenas separadas para cada minijuego.
- `scripts/hub/`: logica de exploracion, barcos, recompensas y evento final.
- `scripts/minigames/`: logica base y scripts especificos de minijuegos.
- `scripts/data/`: datos centrales del juego.
- `docs/`: guias de estructura y exportacion movil.

## Minijuegos

1. **Pesca responsable**: recoge pesca y evita basura marina.
2. **Silla U Bubble**: bubble shooter con simbolos de la Silla U Mantena.
3. **Surf Spondylus**: surfea olas, salta troncos y recoge conchas.
4. **Taller del Astillero**: puzzle de reparacion naval por secuencia.

## Controles

- PC: WASD o flechas para moverse.
- PC: Enter o Espacio para interactuar.
- Movil: botones en pantalla.

## Abrir en Godot

1. Abre Godot 4.6 Standard o una version estable mas reciente.
2. Selecciona **Importar**.
3. Elige esta carpeta.
4. Ejecuta la escena principal.

El siguiente trabajo visual recomendado es crear sprites reales: personaje, muelle, playa, barcos pesqueros, astillero, Spondylus, Silla U Mantena y recompensas.

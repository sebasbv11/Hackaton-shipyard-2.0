# Manta: Ruta Spondylus

Juego movil 2D en Godot 4.6 basado en Manta, Ecuador.

El proyecto queda enfocado en un solo modulo jugable: un plataformas de dos niveles donde el jugador recoge todas las conchas Spondylus y llega a la salida. Los otros minijuegos quedan fuera para que otros companeros puedan conectarlos por modularidad.

## Estado actual

- Proyecto Godot limpio.
- Un solo juego principal.
- 2 niveles jugables.
- Personaje animado por spritesheet.
- Controles para PC y movil.
- Fondos 2D dibujados por codigo con ambiente de playa, puerto y astillero.

## Estructura

- `project.godot`: configuracion del proyecto.
- `scenes/platformer/PlatformerGame.tscn`: escena principal.
- `scripts/platformer/PlatformerGame.gd`: logica completa del plataformas.
- `assets/player/player_retro_sprite_sheet.png`: spritesheet del personaje.
- `docs/`: guias de estructura y exportacion movil.

## Controles

- PC: `A/D` o flechas para moverse.
- PC: `Enter` o `Espacio` para saltar.
- Movil: botones en pantalla.

## Objetivo

1. Recoge todas las conchas Spondylus del nivel.
2. Evita obstaculos.
3. Llega a la salida.
4. Completa los 2 niveles.

## Abrir en Godot

1. Abre Godot 4.6 Standard o una version estable mas reciente.
2. Selecciona **Importar**.
3. Elige esta carpeta.
4. Ejecuta la escena principal.

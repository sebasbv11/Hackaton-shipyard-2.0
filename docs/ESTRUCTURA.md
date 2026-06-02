# Estructura del proyecto

## Modulo principal

Archivo principal:

- `scenes/platformer/PlatformerGame.tscn`
- `scripts/platformer/PlatformerGame.gd`

Responsabilidades:

- Movimiento del jugador.
- Gravedad y salto.
- Plataformas.
- Recoleccion de conchas Spondylus.
- Obstaculos.
- Salida de nivel.
- Cambio entre dos niveles.
- UI y controles tactiles.

## Assets

Archivo:

- `assets/player/player_retro_sprite_sheet.png`

Uso:

- Spritesheet del personaje.
- 4 filas de direccion: abajo, arriba, izquierda y derecha.
- 4 columnas de animacion por direccion.

## Modularidad

Este repo deja un solo modulo jugable listo. Los otros minijuegos pueden conectarse despues creando nuevas escenas independientes y cambiando la escena principal o usando un hub externo del equipo.

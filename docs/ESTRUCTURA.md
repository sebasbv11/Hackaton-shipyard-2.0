# Estructura del proyecto

## Hub principal

Archivo principal:

- `scenes/hub/HubWorld.tscn`
- `scripts/hub/HubWorld.gd`

Responsabilidades:

- Dibujar el muelle, la playa, el mar y EL ASTILLERO.
- Mover al jugador.
- Detectar barcos cercanos.
- Lanzar minijuegos.
- Guardar recompensas obtenidas.
- Activar el evento final.

## Datos del juego

Archivo:

- `scripts/data/GameData.gd`

Responsabilidades:

- Lista de barcos.
- Nombre de cada barco.
- Posicion en el mapa.
- Escena de minijuego asociada.
- Recompensa de cada minijuego.
- Texto del evento final.

## Personaje

Archivo:

- `scripts/characters/Player.gd`

Responsabilidades:

- Cargar la hoja de sprites del personaje placeholder.
- Seleccionar frames por direccion: abajo, arriba, izquierda y derecha.
- Avanzar la animacion cuando el jugador se mueve.
- Dibujar el frame actual en el hub.

## Minijuegos

Base compartida:

- `scripts/minigames/BaseCatchMinigame.gd`

Minijuegos separados:

- `scripts/minigames/Minigame1Pesca.gd`
- `scripts/minigames/Minigame2Balsa.gd`
- `scripts/minigames/Minigame3Spondylus.gd`
- `scripts/minigames/Minigame4Astillero.gd`

Escenas:

- `scenes/minigames/Minigame1Pesca.tscn`
- `scenes/minigames/Minigame2Balsa.tscn`
- `scenes/minigames/Minigame3Spondylus.tscn`
- `scenes/minigames/Minigame4Astillero.tscn`

Los minijuegos comparten senales y controles base, pero sus mecanicas son distintas: recoleccion, bubble shooter, surf y puzzle de reparacion.

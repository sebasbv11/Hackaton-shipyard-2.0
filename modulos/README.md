# Estructura modular

Este proyecto principal de Godot organiza el codigo activo por modulos.

- `menu_principal`: pantalla inicial del proyecto.
- `lobby`: muelle para escoger barcos/minijuegos.
- `minijuego_1`: modulo integrado de "Manta: Del Cerro al Mar".
- `minijuego_3_plataforma`: segundo barco activo, juego de plataforma con niveles y monedas.
- `minijuego_4_flappy`: tercer barco activo, Flappy Pescador.
- `comun`: scripts compartidos/autoloads del proyecto principal.

Entradas principales:

- Menu: `res://modulos/menu_principal/escenas/menu_principal/menu_principal.tscn`
- Lobby: `res://modulos/lobby/escenas/lobby.tscn`
- Minijuego 1: `res://modulos/minijuego_1/escenas/minijuego_1/intro.tscn`
- Minijuego 2 Plataforma: `res://modulos/minijuego_3_plataforma/escenas/escena_principal/escena_principal.tscn`
- Minijuego 3 Flappy: `res://modulos/minijuego_4_flappy/escenas/minijuego_4_flappy/FlappyPescador.tscn`

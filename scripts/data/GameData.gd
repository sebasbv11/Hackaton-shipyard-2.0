extends RefCounted

static var BOATS := [
	{
		"id": "pesca",
		"name": "Pesquero Jocay",
		"place": "Puerto pesquero",
		"symbol": "pesca artesanal",
		"reward": "Estatua del Pescador",
		"color": Color("#f4a261"),
		"position": Vector2(180, 555),
		"scene": "res://scenes/minigames/Minigame1Pesca.tscn",
		"brief": "Recoge pesca responsable y evita basura marina."
	},
	{
		"id": "balsa",
		"name": "Balsa Mantena",
		"place": "Memoria mantena",
		"symbol": "navegacion ancestral",
		"reward": "Silla U Mantena",
		"color": Color("#2a9d8f"),
		"position": Vector2(520, 585),
		"scene": "res://scenes/minigames/Minigame2Balsa.tscn",
		"brief": "Recupera memoria ancestral de las balsas mantenas."
	},
	{
		"id": "spondylus",
		"name": "Barco Spondylus",
		"place": "Playa de Manta",
		"symbol": "concha spondylus",
		"reward": "Concha Spondylus",
		"color": Color("#e76f51"),
		"position": Vector2(145, 805),
		"scene": "res://scenes/minigames/Minigame3Spondylus.tscn",
		"brief": "Atrapa conchas Spondylus entre las olas."
	},
	{
		"id": "astillero",
		"name": "El Astillero",
		"place": "Astilleros de Manta",
		"symbol": "barcos y reparacion naval",
		"reward": "Sello del Astillero",
		"color": Color("#48cae4"),
		"position": Vector2(555, 820),
		"scene": "res://scenes/minigames/Minigame4Astillero.tscn",
		"brief": "Repara piezas del barco para preparar la zarpada."
	}
]

static var FINAL_POSITION := Vector2(560, 980)
const FINAL_TITLE := "Zarpada desde El Astillero"
const FINAL_TEXT := "Las 4 piezas de Manta se unen: pesca, Balsa Mantena, Spondylus y astillero. El Barco Jocay zarpa."

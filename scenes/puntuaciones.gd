extends Control


const ARCHIVO = "user://highscores.json"
const MAX_PUNTAJES = 10

var puntajes: Array = []


func _ready():
	cargar_puntajes()


func cargar_puntajes():
	if not FileAccess.file_exists(ARCHIVO):
		puntajes = []
		return

	var archivo = FileAccess.open(ARCHIVO, FileAccess.READ)
	var texto = archivo.get_as_text()
	archivo.close()

	var datos = JSON.parse_string(texto)

	if datos is Array:
		puntajes = datos


func guardar_puntajes():
	var archivo = FileAccess.open(ARCHIVO, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(puntajes))
	archivo.close()


func agregar_puntaje(nombre: String, puntos: int):
	puntajes.append({
		"nombre": nombre,
		"puntos": puntos
	})

	puntajes.sort_custom(func(a, b):
		return a["puntos"] > b["puntos"]
	)

	if puntajes.size() > MAX_PUNTAJES:
		puntajes.resize(MAX_PUNTAJES)

	guardar_puntajes()

@onready var slider_vol = $ColorRect/VBoxContainer/HSlider
@onready var res_option_btn = $ColorRect/VBoxContainer/OptionButton

var presion_vol = false

var presion_res = false



# Called when the node enters the scene tree for the first time.
func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/control.tscn")

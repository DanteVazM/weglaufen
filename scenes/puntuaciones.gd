extends Control

const ARCHIVO = "user://highscores.json"
const MAX_PUNTAJES = 16

var puntajes: Array = []

@onready var label_tabla = $ColorRect/VBoxContainer/label_tabla
@onready var btn_prueba = $ColorRect/VBoxContainer/BtnPrueba


func _ready():
	cargar_puntajes()
	btn_prueba.pressed.connect(_on_btn_prueba_pressed)
	actualizar_tabla()


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
	puntajes.append({"nombre": nombre, "puntos": puntos})

	puntajes.sort_custom(func(a, b):
		return a["puntos"] > b["puntos"]
	)

	if puntajes.size() > MAX_PUNTAJES:
		puntajes.resize(MAX_PUNTAJES)

	guardar_puntajes()


func actualizar_tabla():
	var texto = ""
	for p in puntajes:
		texto += "%s:%05d\n" % [p["nombre"], p["puntos"]]
	label_tabla.text = texto


# --- MINI PRUEBA: un click agrega un puntaje aleatorio ---
func _on_btn_prueba_pressed():
	var nombres = ["mango", "agus", "joaco", "rodrigo", "pela", "lucas", "manu", "milena"]
	agregar_puntaje(nombres.pick_random(), randi_range(0, 99999))
	actualizar_tabla()


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/control.tscn")

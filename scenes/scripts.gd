extends Control



@onready var slider_vol = $ColorRect/VBoxContainer/HSlider
@onready var res_option_btn = $ColorRect/VBoxContainer/OptionButton

var presion_vol = false

var presion_res = false

const RESOLUCIONES := [
	Vector2i(1080, 720),   # índice 0
	Vector2i(1280, 720),   # índice 1
	Vector2i(1920, 1080),  # índice 2
]

func _on_resolucion_seleccionada(indice: int) -> void:
	var nueva_res: Vector2i = RESOLUCIONES[indice]
	var ventana := get_window()

	if ventana.mode == Window.MODE_FULLSCREEN:
		ventana.mode = Window.MODE_WINDOWED

	ventana.size = nueva_res

	var pantalla := DisplayServer.window_get_current_screen()
	var tam_pantalla := DisplayServer.screen_get_size(pantalla)
	var pos_pantalla := DisplayServer.screen_get_position(pantalla)
	ventana.position = pos_pantalla + (tam_pantalla - nueva_res) / 2


func _ready() -> void:
	# Si ya tienes un _ready(), pega estas líneas dentro y no crees otro
	res_option_btn.item_selected.connect(_on_resolucion_seleccionada)
	var indice := RESOLUCIONES.find(get_window().size)
	if indice != -1:
		res_option_btn.select(indice)


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/control.tscn")


func _on_volumen_pressed() -> void:
	presion_vol = !presion_vol 
	
	slider_vol.visible = presion_vol
		
func _on_resolucion_pressed() -> void:
	
	var nueva_res: Vector2i = RESOLUCIONES[indice]
	var ventana := get_window()

	if ventana.mode == Window.MODE_FULLSCREEN:
		ventana.mode = Window.MODE_WINDOWED

	ventana.size = nueva_res

	var pantalla := DisplayServer.window_get_current_screen()
	var tam_pantalla := DisplayServer.screen_get_size(pantalla)
	var pos_pantalla := DisplayServer.screen_get_position(pantalla)
	ventana.position = pos_pantalla + (tam_pantalla - nueva_res) / 2

	
	presion_res = !presion_res
	
	res_option_btn.visible = presion_res

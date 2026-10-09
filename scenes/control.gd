extends Control

@onready var opt_screen = $opciones_screen


func _on_jugar_pressed():
	get_tree().change_scene_to_file("res://scenes/working_road_example.tscn")


func _on_opciones_pressed():
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_puntuaciones_pressed():
	get_tree().change_scene_to_file("res://scenes/puntuaciones.tscn")
	

func _on_salir_pressed() :
	get_tree().quit()

extends Control

@onready var opt_screen = $opciones_screen


func _on_jugar_pressed():
	get_tree().change_scene_to_file("res://scenes/mundos/ciudad.tscn")


func _on_opciones_pressed():
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_puntuaciones_pressed():
	get_tree().change_scene_to_file("res://scenes/2d/puntajes.tscn")
	

func _on_salir_pressed() :
	get_tree().quit()

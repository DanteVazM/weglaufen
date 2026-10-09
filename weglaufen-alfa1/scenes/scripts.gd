extends Control

@onready var slider_vol = $ColorRect/VBoxContainer/HSlider
@onready var res_option_btn = $ColorRect/VBoxContainer/OptionButton

var presion_vol = false

var presion_res = false


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/control.tscn")


func _on_volumen_pressed() -> void:
	presion_vol = !presion_vol 
	
	slider_vol.visible = presion_vol
		
func _on_resolucion_pressed() -> void:
	presion_res = !presion_res
	
	res_option_btn.visible = presion_res

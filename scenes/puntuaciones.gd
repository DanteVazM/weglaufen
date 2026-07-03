extends Control

@onready var slider_vol = $ColorRect/VBoxContainer/HSlider
@onready var res_option_btn = $ColorRect/VBoxContainer/OptionButton

var presion_vol = false

var presion_res = false

# Called when the node enters the scene tree for the first time.
func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/control.tscn")

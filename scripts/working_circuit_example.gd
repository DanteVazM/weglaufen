extends Node3D

@onready var car = get_tree().get_first_node_in_group("player")

@onready var tiempo_label = $TimerLabel
@onready var puntaje_label = $PuntajeLabel
@onready var timer = $Timer
@onready var total_time_seconds: int = 0
@onready var hp_bar = $VidaLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.start()
	car.hp_changed.connect(_on_car_hp_changed)

func _on_car_hp_changed(new_hp: int) -> void:
	hp_bar.text = str(new_hp)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_timer_timeout():
	total_time_seconds += 1
	var m = int(total_time_seconds / 60)
	var s = total_time_seconds - m * 60
	$TimerLabel.text = '%02d:%02d' % [m, s]
	puntaje_label.text = str(s)
	#str(int(torque)-300).replace("-", "")

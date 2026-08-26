extends VehicleBody3D

@onready var HPbar = $HUD/HPbar

@export var torque: int = 2000
@export var max_RPM = 600
@export var turn_speed: float = 3.0
@export var turn_amount: float = 0.4
@export var wheel_traction_left: VehicleWheel3D
@export var wheel_traction_right: VehicleWheel3D

var max_hp = 50



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	HPbar.max_value = max_hp

func update_HUD():
	HPbar.value = global.hp
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_HUD()
	
	var dirrection = Input.get_action_strength("Acelerador") - Input.get_action_strength("Freno")
	var steering_direction = Input.get_action_strength("Izqda") - Input.get_action_strength("Der")
	
	var RPM_left = wheel_traction_left.get_rpm()
	var RPM_right = wheel_traction_right.get_rpm()
	var RPM = (RPM_left + RPM_right) / 2.0
	
	
	engine_force = dirrection * torque * (1.0 - RPM/max_RPM)
	steering = lerp(steering, steering_direction * turn_amount, turn_speed * delta)

	if dirrection == 0:
		brake = 3


func _on_hurt_box_hurted() -> void:
	print("HURT")

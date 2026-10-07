extends VehicleBody3D

@onready var HPbar = $HUD/HPbar

@export var torque: int = 2000
@export var max_RPM = 600
@export var turn_speed: float = 3.0
@export var turn_amount: float = 0.4
@export var wheel_traction_left: VehicleWheel3D
@export var wheel_traction_right: VehicleWheel3D

var hp: int = 30
var max_hp = 100
var invulnerable: bool = false
var dead: bool = false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	if dead or invulnerable:
		return
	if body.is_in_group("obstaculo"):
		take_damage(10)
		if dead:
			return
		invulnerable = true
		await get_tree().create_timer(0.5).timeout
		invulnerable = false
		
		
func update_HUD():
	HPbar.value = hp

func take_damage(amount: int) -> void:
	hp -= amount
	print("HP:", hp)
	if hp <= 0:
		die()

func die() -> void:
	dead = true
	print("Car destroyed!")
	get_tree().change_scene_to_file("res://scenes/2d/game_over.tscn")
	
func _physics_process(delta: float) -> void:
	update_HUD()

	var dirrection = Input.get_action_strength("Acelerador") - Input.get_action_strength("Freno")
	var steering_direction = Input.get_action_strength("Izqda") - Input.get_action_strength("Der")

	var RPM_left = wheel_traction_left.get_rpm()
	var RPM_right = wheel_traction_right.get_rpm()
	var RPM = (RPM_left + RPM_right) / 2.0

	engine_force = dirrection * torque * (1.0 - RPM / max_RPM)
	steering = lerp(steering, steering_direction * turn_amount, turn_speed * delta)

	if dirrection == 0:
		brake = 2
	else:
		brake = 0

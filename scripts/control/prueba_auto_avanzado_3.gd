extends VehicleBody3D

@export var torque: int = 2000
@export var max_RPM = 600
@export var turn_speed: float = 3.0
@export var turn_amount: float = 0.4
@export var wheel_traction_left: VehicleWheel3D
@export var wheel_traction_right: VehicleWheel3D

# Sound Claude
@export var pitch_min: float = 0.8      # pitch at idle
@export var pitch_max: float = 2.5      # pitch at top RPM
@export var pitch_smooth: float = 6.0   # higher = reacts faster
@onready var engine_sound: AudioStreamPlayer3D = get_node_or_null("Audio/AccelerationPlayer") as AudioStreamPlayer3D

var hp: int = 100 #Actually it is 100
var max_hp = 100
var invulnerable: bool = false
var dead: bool = false

signal died
signal hp_changed(new_hp)

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	body_entered.connect(_on_body_entered)
	add_to_group("player")
	
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
		
func take_damage(amount: int) -> void:
	hp -= amount
	print("HP:", hp)
	hp_changed.emit(hp)
	if hp <= 0:
		die()

func die() -> void:
	dead = true
	print("Car destroyed!")
	died.emit()
	get_tree().change_scene_to_file("res://scenes/2d/pantalla_final.tscn")
	
func _physics_process(delta: float) -> void:
	var dirrection = Input.get_action_strength("Acelerador") - Input.get_action_strength("Freno")
	var steering_direction = Input.get_action_strength("Izqda") - Input.get_action_strength("Der")

	var RPM_left = wheel_traction_left.get_rpm()
	var RPM_right = wheel_traction_right.get_rpm()
	var RPM = (RPM_left + RPM_right) / 2.0

	engine_force = dirrection * torque * (1.0 - RPM / max_RPM)
	
	# Engine sound: pitch rises with wheel RPM and with the throttle
	if engine_sound != null:
		var rpm_ratio := clampf(abs(RPM) / max_RPM, 0.0, 1.0)
		var throttle := clampf(abs(dirrection), 0.0, 1.0)
		var target_pitch := lerpf(pitch_min, pitch_max, rpm_ratio) + throttle * 0.15
		engine_sound.pitch_scale = lerpf(engine_sound.pitch_scale, target_pitch, pitch_smooth * delta)
	
	steering = lerp(steering, steering_direction * turn_amount, turn_speed * delta)

	if dirrection == 0:
		brake = 2
	else:
		brake = 0

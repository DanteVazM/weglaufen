extends VehicleBody3D

@export var torque: float = 1500.0
@export var max_steer: float = 0.4
@export var steer_speed: float = 3.0
@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.0

var target: Node3D
var attack_timer := 0.0

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	# o: target = $"../Nissan GTR"

func _physics_process(delta: float) -> void:
	if target == null:
		return

	attack_timer = max(attack_timer - delta, 0.0)

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	# Dirección al objetivo en el espacio local del vehículo (adelante = -Z)
	var local_dir := global_transform.basis.inverse() * to_target
	var angle := atan2(-local_dir.x, -local_dir.z)

	var steer_target := clampf(angle, -max_steer, max_steer)
	steering = lerp(steering, steer_target, steer_speed * delta)

	if distance > attack_range:
		engine_force = torque
		brake = 0.0
	else:
		engine_force = 0.0
		brake = 5.0
		if attack_timer <= 0.0:
			_attack()
			attack_timer = attack_cooldown

func _attack() -> void:
	print("¡El enemigo te atacó!")
	if target.has_method("take_damage"):
		target.take_damage(10)

extends VehicleBody3D

@export var torque: float = 500.0
@export var max_RPM: float = 250.0
@export var max_steer: float = 0.4
@export var steer_speed: float = 3.0
@export var steer_sign: float = -1.0          # poné -1 si gira para el lado contrario
@export var accel_smoothing: float = 3.0
@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.0
@export var stuck_speed: float = 1.5         # por debajo de esta velocidad cuenta como "parado"
@export var stuck_time: float = 0.8          # tiempo parado antes de retroceder
@export var reverse_time: float = 1.3        # cuánto retrocede

var target: Node3D
var traction_wheels: Array[VehicleWheel3D] = []
var attack_timer := 0.0
var stuck_timer := 0.0
var reverse_timer := 0.0

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	for child in get_children():
		if child is VehicleWheel3D and child.use_as_traction:
			traction_wheels.append(child)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	attack_timer = max(attack_timer - delta, 0.0)

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	# Ángulo hacia el objetivo (adelante = -Z). Positivo = objetivo a la izquierda
	var local_dir := global_transform.basis.inverse() * to_target
	var angle := atan2(-local_dir.x, -local_dir.z)

	var speed := linear_velocity.length()
	var rpm := 0.0
	for w in traction_wheels:
		rpm += w.get_rpm()
	if traction_wheels.size() > 0:
		rpm /= traction_wheels.size()
	var power := clampf(1.0 - abs(rpm) / max_RPM, 0.0, 1.0)

	var target_force := 0.0
	var target_brake := 0.0
	var steer_target := 0.0

	if reverse_timer > 0.0:
		# --- MARCHA ATRÁS ---
		reverse_timer -= delta
		target_force = -torque * 0.7 * power
		# marcha atrás: se gira al revés para que la trompa apunte al objetivo
		steer_target = clampf(-angle, -max_steer, max_steer)
	else:
		# --- AVANZAR ---
		var steer_limit := max_steer * clampf(1.0 - speed / 40.0, 0.3, 1.0)
		steer_target = clampf(angle, -steer_limit, steer_limit)

		if distance > attack_range:
			target_force = torque * power
			if abs(angle) > 1.2:
				target_force *= 0.4   # aflojar para poder doblar

			# Detectar atasco: quiere avanzar pero no se mueve
			if speed < stuck_speed:
				stuck_timer += delta
				if stuck_timer >= stuck_time:
					reverse_timer = reverse_time
					stuck_timer = 0.0
			else:
				stuck_timer = 0.0
		else:
			stuck_timer = 0.0
			target_brake = 5.0
			if attack_timer <= 0.0:
				_attack()
				attack_timer = attack_cooldown

	steering = lerp(steering, steer_target * steer_sign, steer_speed * delta)
	engine_force = lerp(engine_force, target_force, accel_smoothing * delta)
	brake = target_brake

func _attack() -> void:
	if target.has_method("take_damage"):
		target.take_damage(10)

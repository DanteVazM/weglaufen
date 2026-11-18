extends VehicleBody3D
## Policia enemigo: persigue al jugador (grupo "player") usando linea de vision,
## ruta de navegacion, esquiva de paredes, marcha atras y recuperacion de atascos.
## El frente del auto es +Z.

@export var torque: float = 800.0
@export var max_RPM: float = 350.0
@export var max_steer: float = 0.4
@export var steer_speed: float = 4.0
@export var steer_sign: float = 1.0           # poner -1 si gira para el lado contrario
@export var accel_smoothing: float = 3.0
@export var attack_range: float = 6.5         # distancia entre centros para golpear (el auto mide ~6 m)
@export var attack_cooldown: float = 1.0
@export var attack_damage: int = 10
@export var stuck_speed: float = 1.5
@export var stuck_time: float = 0.8
@export var stuck_min_distance: float = 9.0   # cerca del jugador no cuenta como atasco
@export var reverse_time: float = 1.2
@export var ray_length: float = 10.0
@export var repath_interval: float = 0.3
@export var close_range: float = 25.0         # por debajo: persecucion directa y marcha atras
@export var far_despawn: float = 150.0        # mas lejos que esto, desaparece

var nav: NavigationAgent3D
var target: Node3D
var traction_wheels: Array[VehicleWheel3D] = []
var attack_timer := 0.0
var stuck_timer := 0.0
var reverse_timer := 0.0
var reverse_steer := 0.0
var flipped_timer := 0.0
var repath_timer := 0.0
var grace := 2.0                              # segundos sin detectar atasco al nacer o retroceder
var backing_to_target := false
var backing_lock := 0.0
var hit_sfx: AudioStreamPlayer3D

func _ready() -> void:
	# El agente de navegacion se crea solo si no esta en la escena
	hit_sfx = get_node_or_null("ChoqueSfx") as AudioStreamPlayer3D
	nav = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if nav == null:
		nav = NavigationAgent3D.new()
		nav.path_desired_distance = 4.0
		nav.target_desired_distance = 3.0
		add_child(nav)

	target = get_tree().get_first_node_in_group("player") as Node3D

	for child in get_children():
		if child is VehicleWheel3D and child.use_as_traction:
			traction_wheels.append(child)

func _physics_process(delta: float) -> void:
	# Buscar (o volver a buscar) al jugador
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node3D
		if target == null:
			return

	# Si el jugador ya murio, quedarse quieto (la escena esta por cambiar)
	if target.get("dead") == true:
		engine_force = 0.0
		brake = 5.0
		return

	attack_timer = max(attack_timer - delta, 0.0)
	grace = max(grace - delta, 0.0)
	backing_lock = max(backing_lock - delta, 0.0)

	# Dado vuelta mucho tiempo: desaparece
	if global_transform.basis.y.dot(Vector3.UP) < 0.3:
		flipped_timer += delta
		if flipped_timer > 2.0:
			queue_free()
			return
	else:
		flipped_timer = 0.0

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	# Red de seguridad: muy lejos del jugador
	if distance > far_despawn:
		queue_free()
		return

	# Ruta (solo se usa si no hay linea de vision)
	repath_timer -= delta
	if repath_timer <= 0.0:
		nav.target_position = target.global_position
		repath_timer = repath_interval

	var los := _has_line_of_sight()
	var aim_point := _get_aim_point(los)

	var to_aim := aim_point - global_position
	to_aim.y = 0.0
	var local_dir := global_transform.basis.inverse() * to_aim
	var angle := atan2(local_dir.x, local_dir.z)   # positivo = izquierda

	var speed := linear_velocity.length()
	var rpm := 0.0
	for w in traction_wheels:
		rpm += w.get_rpm()
	if traction_wheels.size() > 0:
		rpm /= traction_wheels.size()
	var power := clampf(1.0 - abs(rpm) / max_RPM, 0.0, 1.0)

	# Conviene ir marcha atras hacia el jugador? (cerca, a la vista y detras)
	if los and distance < close_range and distance > attack_range and backing_lock <= 0.0:
		if not backing_to_target and abs(angle) > 2.3:
			backing_to_target = true
		elif backing_to_target and abs(angle) < 1.7:
			backing_to_target = false
	else:
		backing_to_target = false

	var target_force := 0.0
	var target_brake := 0.0
	var steer_target := 0.0

	if reverse_timer > 0.0:
		# --- RETROCESO POR ATASCO ---
		reverse_timer -= delta
		target_force = -torque * 0.7 * power
		steer_target = reverse_steer

	elif backing_to_target:
		# --- MARCHA ATRAS HACIA EL JUGADOR ---
		target_force = -torque * 0.6 * power
		steer_target = clampf(local_dir.x * 0.5, -max_steer, max_steer)
		if speed < stuck_speed and grace <= 0.0:
			stuck_timer += delta
			if stuck_timer >= stuck_time:
				backing_to_target = false
				backing_lock = 3.0   # no volver a ir marcha atras por 3 s
				stuck_timer = 0.0
				grace = 1.5
		else:
			stuck_timer = 0.0

	else:
		# --- AVANZAR ---
		var steer_limit := max_steer * clampf(1.0 - speed / 40.0, 0.3, 1.0)
		steer_target = clampf(angle, -steer_limit, steer_limit)

		# Esquivar paredes, salvo que tenga al jugador a la vista y cerca
		var avoid := 0.0
		if not (los and distance < close_range):
			avoid = _avoid_obstacles(angle)
			if avoid != 0.0:
				steer_target = avoid * max_steer

		if distance > attack_range:
			target_force = torque * power
			if abs(angle) > 1.2 or avoid != 0.0:
				target_force *= 0.4   # aflojar para poder doblar

			# Detectar atasco (no cuando esta casi encima del jugador)
			if speed < stuck_speed and grace <= 0.0 and distance > stuck_min_distance:
				stuck_timer += delta
				if stuck_timer >= stuck_time:
					reverse_timer = reverse_time
					reverse_steer = max_steer * (1.0 if randf() < 0.5 else -1.0)
					stuck_timer = 0.0
					grace = reverse_time + 1.5
			else:
				stuck_timer = 0.0
		else:
			# --- EN CONTACTO: frenar y golpear con cooldown ---
			stuck_timer = 0.0
			target_brake = 5.0
			if attack_timer <= 0.0:
				_attack()
				attack_timer = attack_cooldown

	steering = lerp(steering, steer_target * steer_sign, steer_speed * delta)
	engine_force = lerp(engine_force, target_force, accel_smoothing * delta)
	brake = target_brake

# Punto hacia el que apunta el auto
func _get_aim_point(los: bool) -> Vector3:
	if los:
		return target.global_position
	if not nav.is_navigation_finished():
		var next_pos := nav.get_next_path_position()
		if next_pos.distance_to(global_position) > 2.0:
			return next_pos
	return target.global_position

# Hay algo solido entre el enemigo y el jugador?
func _has_line_of_sight() -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.0
	var to := target.global_position + Vector3.UP * 1.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	var c = hit.collider
	return c == target or (c is Node and c.is_in_group("enemigo"))

func _avoid_obstacles(angle_to_target: float) -> float:
	var space := get_world_3d().direct_space_state
	var fwd := global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var origin := global_position + Vector3.UP * 0.8 + fwd * 2.5

	var bias := 0.0
	for a in [-35.0, 0.0, 35.0]:   # positivo = izquierda
		var dir := fwd.rotated(Vector3.UP, deg_to_rad(a))
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * ray_length)
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit.collider == target:
			continue
		var closeness := 1.0 - origin.distance_to(hit.position) / ray_length
		if a > 0.0:
			bias -= closeness
		elif a < 0.0:
			bias += closeness
		else:
			bias += closeness * (1.0 if angle_to_target >= 0.0 else -1.0)
	return clampf(bias, -1.0, 1.0)

func _attack() -> void:
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
		if hit_sfx != null:
			hit_sfx.play()

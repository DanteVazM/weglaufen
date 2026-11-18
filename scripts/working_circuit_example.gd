extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemigos/pruebas/policia_basico4.tscn")

@export var max_enemies: int = 5
@export var front_chance: float = 0.5   # 0.5 = mitad adelante, mitad atrás
@export var spawn_every: int = 5        # segundos entre spawns

@onready var car = get_tree().get_first_node_in_group("player")
@onready var tiempo_label = $TimerLabel
@onready var puntaje_label = $PuntajeLabel
@onready var hp_bar = $VidaLabel

#Cosstados
@export var side_chance: float = 0.4    # probabilidad de aparecer a un costado
@export var side_lead_min: float = 10.0 # cuanto adelante del jugador aparece (m)
@export var side_lead_max: float = 35.0
@export var side_dist_min: float = 30.0 # distancia lateral al jugador (m)
@export var side_dist_max: float = 45.0

var total_time_seconds: int = 0
var last_move_dir := Vector3.ZERO

func _ready() -> void:
	global.new_run()
	$Timer.start()
	if car == null:
		push_error("No hay ningún nodo en el grupo 'player'.")
		return
	car.hp_changed.connect(_on_car_hp_changed)
	_on_car_hp_changed(car.hp)

func _physics_process(_delta: float) -> void:
	if car is RigidBody3D and car.linear_velocity.length() > 3.0:
		var v: Vector3 = car.linear_velocity
		v.y = 0.0
		last_move_dir = v.normalized()

func _on_car_hp_changed(new_hp: int) -> void:
	hp_bar.text = str(new_hp)

func _on_timer_timeout() -> void:
	total_time_seconds += 1
	var m := int(total_time_seconds / 60)
	var s := total_time_seconds - m * 60
	tiempo_label.text = "%02d:%02d" % [m, s]
	puntaje_label.text = str(total_time_seconds)
	global.final_score = total_time_seconds

	if total_time_seconds % spawn_every == 0:
		spawn_enemy()

# ---------- Spawn de enemigos ----------

func spawn_enemy() -> void:
	if car == null:
		return

	# Contar solo enemigos cercanos: los que quedaron lejos no bloquean el spawn
	var nearby := 0
	for e in get_tree().get_nodes_in_group("enemigo"):
		if e is Node3D and e.global_position.distance_to(car.global_position) < 100.0:
			nearby += 1
	if nearby >= max_enemies:
		return

	var roll := randf()
	var ok := false
	if roll < side_chance:
		ok = _try_spawn_side()
	elif roll < side_chance + front_chance:
		ok = _try_spawn(true)
	else:
		ok = _try_spawn(false)

	if not ok:
		_try_spawn(false)   # plan B: atras

# Costados: un poco adelante del jugador y desplazado a izquierda o derecha
func _try_spawn_side() -> bool:
	if last_move_dir == Vector3.ZERO:
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false

	var right := last_move_dir.cross(Vector3.UP).normalized()

	for i in 8:
		var side := 1.0 if randf() < 0.5 else -1.0
		var lead := randf_range(side_lead_min, side_lead_max)
		var lateral := randf_range(side_dist_min, side_dist_max)
		var pos: Vector3 = car.global_position + last_move_dir * lead + right * side * lateral + Vector3(0, 1.0, 0)
		if _is_in_camera_view(cam, pos):
			continue
		_spawn_at(pos)
		return true
	return false

# Adelante o atras
func _try_spawn(in_front: bool) -> bool:
	if last_move_dir == Vector3.ZERO:
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false

	var base_dir := last_move_dir if in_front else -last_move_dir

	# Abrir el angulo en cada intento hasta encontrar un punto fuera de la camara
	for i in 12:
		var angle := deg_to_rad(i * 10.0) * (1.0 if randf() < 0.5 else -1.0)
		var dir := base_dir.rotated(Vector3.UP, angle)
		var dist := randf_range(35.0, 55.0) if in_front else randf_range(25.0, 40.0)
		var pos: Vector3 = car.global_position + dir * dist + Vector3(0, 1.0, 0)
		if _is_in_camera_view(cam, pos):
			continue
		_spawn_at(pos)
		return true
	return false

# Crea el policia en una posicion, mirando al jugador
func _spawn_at(pos: Vector3) -> void:
	var enemy := ENEMY_SCENE.instantiate() as Node3D
	add_child(enemy)
	enemy.add_to_group("enemigo")
	enemy.global_position = pos   # primero la posicion...
	enemy.look_at(Vector3(car.global_position.x, pos.y, car.global_position.z), Vector3.UP, true)   # ...despues mirar

func _is_in_camera_view(cam: Camera3D, pos: Vector3) -> bool:
	for off in [Vector3.ZERO, Vector3(3, 0, 0), Vector3(-3, 0, 0), Vector3(0, 0, 3), Vector3(0, 0, -3)]:
		if cam.is_position_in_frustum(pos + off):
			return true
	return false

extends CharacterBody3D

const SPEED = 5.0
const ACCEL = 30.0
const ATTACK_RANGE = 1.2
const ATTACK_COOLDOWN = 1.0
const TURN_SPEED = 8.0

@onready var target: Node3D = $"../player"

var attack_timer := 0.0

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_timer = max(attack_timer - delta, 0.0)

	# Vector horizontal hacia el jugador
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	var desired := Vector3.ZERO

	if distance > ATTACK_RANGE:
		# Perseguir
		desired = to_target.normalized() * SPEED
	else:
		# En rango: atacar con cooldown
		if attack_timer <= 0.0:
			_attack()
			attack_timer = ATTACK_COOLDOWN

	# Girar solo sobre Y, suavemente, y solo si está lo bastante lejos
	# para que la dirección sea estable (evita el temblor/giro a corta distancia)
	if distance > 0.3:
		var target_angle := atan2(-to_target.x, -to_target.z)
		rotation.y = lerp_angle(rotation.y, target_angle, TURN_SPEED * delta)

	# Aceleración horizontal (sin tocar Y para no pisar la gravedad)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(desired, ACCEL * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

func _attack() -> void:
	print("¡El enemigo te atacó!")

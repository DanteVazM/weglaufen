extends Camera3D

@export var car: Node3D
@export var follow_speed: float = 5.0    # Qué tan rápido la cámara alcanza al auto
@export var rotation_speed: float = 4.0  # Qué tan rápido gira la cámara para ponerse detrás del auto

# Distancia hacia atrás (Z) y hacia arriba (Y) respecto al auto
@export var height_offset: float = 4.0
@export var distance_offset: float = 8.0

func _ready() -> void:
	# Desconecta la cámara de la rotación directa del auto para poder controlarla por código
	top_level = true

func _physics_process(delta: float) -> void:
	if not car:
		return

	# 1. Obtener la posición del auto en el suelo (ignora la altura Y para el cálculo del giro)
	var car_pos = car.global_position
	
	# 2. Obtener la dirección hacia adelante del auto, pero proyectada en el suelo (plano XZ)
	# Esto evita que la cámara se vuelva loca si el auto apunta hacia el cielo o el suelo
	var car_forward = -car.global_transform.basis.z
	car_forward.y = 0
	car_forward = car_forward.normalized()

	# 3. Calcular la posición ideal (Target) detrás del auto usando ese vector nivelado
	var target_pos = car_pos - (car_forward * distance_offset)
	target_pos.y += height_offset # Aplicar la altura deseada

	# 4. Suavizar el movimiento de la cámara hacia la posición ideal
	global_position = global_position.lerp(target_pos, follow_speed * delta)

	# 5. Mantener la cámara mirando al auto, pero forzando que se mantenga nivelada (Up vector = Vector3.UP)
	look_at(car_pos, Vector3.UP)

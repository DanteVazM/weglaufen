extends SpringArm3D

var SensiblidadDeMouse = 0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_as_top_level(true)


#ESTE PEDAZO DE "CODIGO" problablemnte lo termine DESCARTANDO porque no necesito GIRAR la camara (creo) en el juego
func _input(event: InputEvent) -> void:
	pass
	# Algo algo, esto hace algo con el mouse bah blah gira camara o algo
	#rotation_degrees.x -= event.relative.y * SensiblidadDeMouse
	#rotation_degrees.x = clamp(rotation_degrees.x, -90.0,-10.0)
	
	#rotation_degrees.y -= event.relative.x * SensiblidadDeMouse
	#rotation_degrees.y = clamp(rotation_degrees.y, 0.0,360.0)

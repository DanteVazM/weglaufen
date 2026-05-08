extends VehicleBody3D

var max_rpm = 450 # ????
var max_torque = 300 #"Velocidad"
var turn_speed = 3 #Determina que tan rapido giran las ruedas
var turn_amount = 0.9 #Determina "el angulo" de giro de las reudas

func _physics_process(delta: float) -> void:
	$CamArm.position = position
	
	var dirrection = Input.get_action_strength("Acelerador") - Input.get_action_strength("Freno")
	var steering_direction = Input.get_action_strength("Izqda") - Input.get_action_strength("Der")
	
	var RPM_Izqda = abs($BackLeft.get_rpm())
	var RPM_Der = abs($BackRight.get_rpm())
	var RPM = (RPM_Izqda + RPM_Der) / 2.0
	
	#Da "potencia" al auto, en el sentido de que esto hace que avanze
	var torque = dirrection * max_torque * (1.0 - RPM / max_rpm) #La multiplicacion al final hace que mientras mas gires, mas baja el torque
	engine_force = torque
	
	steering = lerp(steering, steering_direction * turn_amount, turn_speed * delta)
	
	if dirrection == 0:
		brake=2

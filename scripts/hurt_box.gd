extends Area3D

class_name HurtBox

signal hurted()
signal died()

func get_damage(value: int):
	global.hp -= value
	
	hurted.emit()
	
	if global.hp <= 0:
		died.emit
	

extends Area3D
class_name HitBox

func _ready() -> void:
	set_active(false)

func set_active(boolean: bool) -> void:	
	for child in get_children():
		if child is not CollisionShape3D: continue
		
		child.disabled = not boolean

func _on_area_entered(area: Area3D):
	if area is HurtBox:
		area.get_damage(1)

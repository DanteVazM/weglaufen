extends Area3D


func _on_area_entered(area: Area3D) -> void:
	if area is HurtBox:
		area.get_damage(1)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass 

class_name Hitbox extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(9, true)
	
	body_entered.connect(func(body) -> void:
		if body is not PlayerCharacter: return
		body.die()
	)

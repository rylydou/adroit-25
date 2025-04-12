extends StaticBody2D


## If false then the block will respawn on room enter
@export var is_persistent := true
@export var strength := 0


@onready var collision_shape: CollisionShape2D = %"Collision"


var is_destroyed := false


## 0 = weak punch, 1 = strong punch
func receive_punch(punch_strength: int) -> void:
	if punch_strength < strength: return
	if is_destroyed: return
	
	is_destroyed = true
	collision_shape.disabled = true
	# hide()
	var tween := create_tween()
	tween.tween_property(self, ^"scale", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, ^"modulate:a", 0.0, 0.75)


func room_enter() -> void:
	if is_persistent: return
	
	is_destroyed = false
	collision_shape.disabled = false
	show()

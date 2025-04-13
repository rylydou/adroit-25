extends StaticBody2D


## If false then the block will respawn on room enter
@export var is_persistent := true
@export var strength := 0


@onready var collision_shape: CollisionShape2D = %"Collision"


var is_destroyed := false
var tween: Tween


func _enter_tree() -> void:
	Game.entered_room.connect(room_enter)


func room_enter() -> void:
	if is_persistent: return
	
	if tween: tween.kill()
	is_destroyed = false
	collision_shape.set_deferred("disabled", false)
	scale = Vector2.ONE
	modulate.a = 1.0
	show()


## 0 = weak punch, 1 = strong punch
func receive_punch(punch_strength: int) -> void:
	if punch_strength < strength: return
	if is_destroyed: return
	
	is_destroyed = true
	collision_shape.disabled = true
	# hide()
	tween = create_tween()
	tween.tween_property(self, ^"scale", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, ^"modulate:a", 0.0, 0.75)

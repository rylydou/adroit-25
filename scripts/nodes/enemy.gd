extends PathFollow2D

@export var speed:float
@export var sprite: Sprite2D
var oldpos
func _process(delta: float) -> void:
	oldpos = global_position
	progress += speed * delta
	if global_position.x - oldpos.x < -0.25:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		

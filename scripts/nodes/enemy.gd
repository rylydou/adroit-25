extends PathFollow2D

@export var speed:float
@export var sprite: Sprite2D
@export var anim_tree: AnimationTree
@export var anim_speed:= 1.0
@export var anim_speed_variability: float
@export var rotation_speed: float
@export var rotation_speed_variability: float
@export var max_rotation: float
@export var max_rotation_variability:float

var true_max_rotation:float
var true_rotation_speed:float
var time:= 0.0

func _ready():
	anim_tree.tree_root.start_offset = randf() * anim_speed
	anim_tree.tree_root.timeline_length = (anim_speed - anim_speed_variability/2) + randf() * anim_speed_variability
	true_max_rotation = (max_rotation - max_rotation_variability/2) + randf() * max_rotation_variability
	true_rotation_speed = (rotation_speed - rotation_speed_variability/2) + randf() * rotation_speed_variability
	true_rotation_speed = true_rotation_speed / true_max_rotation

func _process(delta: float) -> void:
	progress += speed * delta
	
	handle_flipping()
	
	handle_rotation()
	
	time += delta

func handle_flipping():
	var direction = get_parent().curve.sample_baked_with_rotation(progress).get_rotation()
	var direction_vector = Vector2.from_angle(direction)
	var x_direction = direction_vector.x
	
	if is_zero_approx(x_direction):
		pass
	elif x_direction > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
		
func handle_rotation():
	
	
	if sprite.flip_h:
		sprite.rotation = -sin(time * true_rotation_speed) * true_max_rotation
	else:
		sprite.rotation = sin(time * true_rotation_speed) * true_max_rotation

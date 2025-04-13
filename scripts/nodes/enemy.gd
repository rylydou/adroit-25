extends PathFollow2D

@export var speed:float
@export var sprite: Sprite2D
@export var anim_tree: AnimationTree
@export var anim_speed:= 1.0
@export var variability: float
var oldpos

func _ready():
	anim_tree.tree_root.start_offset = randf() * anim_speed
	anim_tree.tree_root.timeline_length = (anim_speed - variability/2) + randf() * variability

func _process(delta: float) -> void:
	oldpos = global_position
	progress += speed * delta
	if is_zero_approx(global_position.x - oldpos.x):
		if sprite.flip_h != null:
			sprite.flip_h = true
	else:
		if sprite.flip_h != null:
			sprite.flip_h = false
		

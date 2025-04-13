extends PathFollow2D

@export var speed:float
@export var sprite: Sprite2D
@export var anim_tree: AnimationTree
@export var variability: float
var oldpos

func _ready():
	anim_tree.tree_root.start_offset = randf()
	anim_tree.tree_root.timeline_length = (1 - variability/2) + randf() * variability

func _process(delta: float) -> void:
	oldpos = global_position
	progress += speed * delta
	if global_position.x - oldpos.x < -0.25:
		if sprite.flip_h != null:
			sprite.flip_h = true
	else:
		if sprite.flip_h != null:
			sprite.flip_h = false
		

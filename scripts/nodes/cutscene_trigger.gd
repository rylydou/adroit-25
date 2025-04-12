class_name CutsceneTrigger extends ReferenceRect


@export var oneshot := true
@export_multiline var text = ""


func _ready() -> void:
	var area := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = size * 0.5
	area.add_child(collision)
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(9, true)
	area.body_entered.connect(func(body): trigger())
	add_child(area)


func trigger() -> void:
	Game.play_cutscene(text)
	if oneshot:
		queue_free()

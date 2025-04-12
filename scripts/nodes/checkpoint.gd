class_name UnsafeBox extends ReferenceRect


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
	area.set_collision_layer_value(11, true)
	add_child(area)

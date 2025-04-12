class_name Killbox extends ReferenceRect


func _ready() -> void:
	var hitbox := Hitbox.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = size * 0.5
	hitbox.add_child(collision)
	add_child(hitbox)

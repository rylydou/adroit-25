@tool
class_name Room extends ReferenceRect


@export var camera_zoom := 5.0:
	set(value):
		camera_zoom = value
		custom_minimum_size = Vector2(1920, 1080) / value


@export var sfx_music := &"generic"
@export var sfx_ambient := &""


func _ready() -> void:
	if not Engine.is_editor_hint():
		var area := Area2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = size - (Vector2.ONE * 12.0)
		collision.shape = shape
		collision.position = size * 0.5
		collision.debug_color = border_color
		collision.debug_color.a = 0.0
		area.add_child(collision)
		add_child(area)
		
		area.collision_layer = 0
		area.collision_mask = 0
		area.set_collision_mask_value(9, true)
		area.body_entered.connect(func(body):
			if body is PlayerCharacter:
				player_entered()
		)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		border_color = Color.from_ok_hsl(hash(hash(name) % 100), 1.0, 0.5)


func player_entered() -> void:
	Global.current_room = self
	
	var camera := Global.camera
	var rect := get_global_rect()
	camera.limit_top = rect.position.y
	camera.limit_left = rect.position.x
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y
	create_tween().tween_property(camera, ^"zoom", Vector2.ONE * camera_zoom, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

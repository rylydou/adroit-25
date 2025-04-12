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
		shape.size = size
		collision.shape = shape
		collision.position = size / 2
		collision.debug_color = border_color
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
	
	var camera: Camera2D = get_parent().get_node(^"Camera")
	var rect := get_global_rect()
	camera.limit_top = rect.position.y
	camera.limit_left = rect.position.x
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y
	camera.limit_smoothed = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	create_tween().tween_property(camera, ^"zoom", Vector2.ONE * camera_zoom, 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func player_exited() -> void:
	pass

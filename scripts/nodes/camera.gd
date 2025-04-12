class_name Camera extends Camera2D


func _enter_tree() -> void:
	Global.camera = self


func _ready() -> void:
	limit_smoothed = true
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0


func _process(delta: float) -> void:
	var player := Global.player
	
	if not is_instance_valid(player): return
	
	position.x = player.position.x
	
	if (
			player.is_grounded || player.is_climbing
			|| player.position.y >= position.y
			|| player.position.y <= position.y - 8.0 * 8.0
	):
		position.y = player.position.y

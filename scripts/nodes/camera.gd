class_name Camera extends Camera2D


var pound_shake_power := 0.0

var time := 0.0
var target_zoom := 5.0


func _enter_tree() -> void:
	Global.camera = self


func _ready() -> void:
	limit_smoothed = true
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0


func _process(delta: float) -> void:
	time += delta
	
	var player := Global.player
	
	if not is_instance_valid(player): return
	
	position.x = player.position.x
	
	if (
			player.is_grounded || player.is_climbing
			|| player.position.y >= position.y
			|| player.position.y <= position.y - 8.0 * 8.0
	):
		position.y = player.position.y
	
	position_smoothing_speed = 5.0
	if player.state == PlayerCharacter.State.Pound:
		position_smoothing_speed = 20.0
	
	offset.y = pow(sin(time * TAU * 6.0), 2) * pound_shake_power * 8.0
	pound_shake_power = lerpf(pound_shake_power, 0.0, Math.smooth(5.0, delta))
	
	zoom = Vector2.ONE * lerpf(zoom.x, target_zoom, Math.smooth(100 if target_zoom > zoom.x else 1, delta))


func pound_shake() -> void:
	pound_shake_power = 1.0


func reset() -> void:
	reset_smoothing()
	zoom = Vector2.ONE * target_zoom
	print("reset")

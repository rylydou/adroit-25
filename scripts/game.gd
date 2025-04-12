extends CanvasLayer


@onready var fade_animation: AnimationPlayer = %"Fade Animation"


var _transition_callback: Callable


func start_door_transition(target_position: Vector2) -> void:
	get_tree().paused = true
	
	_transition_callback = func():
		Global.player.position = target_position
		for i in 5:
			Global.camera.reset_smoothing()
			await get_tree().process_frame
	
	fade_animation.play(&"in")


func transition_done() -> void:
	_transition_callback.call()
	get_tree().paused = false
	fade_animation.play(&"out")
	
	# for i in 5:
	# 	Global.camera.reset_smoothing()
	# 	await get_tree().process_fram

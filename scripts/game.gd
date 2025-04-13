extends CanvasLayer


@onready var fade_animation: AnimationPlayer = %"Fade Animation"

@onready var cutscene_animation: AnimationPlayer = %"Cutscene Animation"
@onready var cutscene_text_container: Control = %"Cutscene Text Container"


var _transition_callback: Callable


func transition_to_scene(scene_path: String) -> void:
	_transition_callback = func():
		get_tree().change_scene_to_file(scene_path)
		
		for i in 5:
			if is_instance_valid(Global.camera):
				Global.camera.reset_smoothing()
			await get_tree().process_frame
	
	fade_animation.play(&"in")


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


func play_cutscene(text: String) -> void:
	Util.queue_free_children(cutscene_text_container)
	
	var lines := text.split("\n\n", false)
	cutscene_animation.play(&"in")
	
	Global.player.gamepad.enabled = false
	
	for line in lines:
		if line == "[clear]":
			Util.queue_free_children(cutscene_text_container)
			continue
		
		line = Global.translate_button_prompts(line)
		
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.scroll_active = false
		label.fit_content = true
		label.text = "[wave][center]" + line
		label.visible_characters = 0
		cutscene_text_container.add_child(label)
		
		var tween := create_tween()
		tween.tween_property(label, ^"visible_characters", line.length(), line.length() * 0.05)
		await tween.finished
		
		while true:
			await get_tree().process_frame
			if Input.is_anything_pressed():
				break
	
	cutscene_animation.play(&"out")
	Global.player.gamepad.enabled = true

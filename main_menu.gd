extends Control

@export var input_picker: Node

func quit():
	get_tree().quit()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		input_picker.hide()

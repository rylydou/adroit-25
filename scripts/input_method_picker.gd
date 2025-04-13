extends Control


const scene := "res://scenes/world.tscn"


func arrow_keys() -> void:
	Global.input_method = Global.InputMethod.ArrowKeys
	Game.transition_to_scene(scene)

func wasd() -> void:
	Global.input_method = Global.InputMethod.WASD
	Game.transition_to_scene(scene)

func gamepad() -> void:
	Global.input_method = Global.InputMethod.Gamepad
	Game.transition_to_scene(scene)

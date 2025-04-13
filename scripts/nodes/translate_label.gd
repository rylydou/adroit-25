class_name TranslateLabel extends Node


func _ready() -> void:
	get_parent().text = Global.translate_button_prompts(get_parent().text)

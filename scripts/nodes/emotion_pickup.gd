extends Area2D


@export var emotion := &""
@export var color := Color.WHITE
@export var emotion_name := ""
@export var emotion_description := ""
@export var emotion_usage_tip := ""

@export_multiline var cutscene_text := ""


var triggered := false


func _ready() -> void:
	$Color.modulate = color


func _on_body_entered(body: Node2D) -> void:
	if body is not PlayerCharacter: return
	if triggered: return
	triggered = true
	
	SFX.event(&"emotion_pickup").at(self).play()
	
	Global.emotions.append(emotion)
	await Game.play_cutscene(cutscene_text)
	
	queue_free()

extends Area2D


@export var emotion := &""

@export var emotion_name := ""
@export_multiline var emotion_description := ""
@export_multiline var emotion_usage := ""


func _on_body_entered(body: Node2D) -> void:
	if body is not PlayerCharacter: return
	
	queue_free()
	
	Global.emotions.append(emotion)

extends Node2D
class_name emotion_pickup 

enum emotions {FEAR, JOY, DEPRESSION, ANGER, LOVE}
@export var emotion: emotions 
@export var player : PlayerCharacter



func _on_collision_shape_2d_child_entered_tree(node: Node) -> void:
	if Node == player:
		if emotion == emotions.FEAR:
			Global.fear = true
			print("GOT FEAR")
		if emotion == emotions.JOY:
			Global.joy = true
		if emotion == emotions.DEPRESSION:
			Global.depression = true
		if emotion == emotions.ANGER:
			Global.anger = true
		if emotion == emotions.LOVE:
			Global.love = true
		

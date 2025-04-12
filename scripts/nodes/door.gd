extends Area2D


@export var target: Node2D


func receive_interact() -> void:
	Game.start_door_transition(target.global_position)

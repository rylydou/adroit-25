extends Area2D


@export var target: Node2D


func receive_interact() -> void:
	Game.start_door_transition(target.global_position)



func _on_body_exited(body:Node2D) -> void:
	$Hint.hide()


func _on_body_entered(body:Node2D) -> void:
	$Hint.show()

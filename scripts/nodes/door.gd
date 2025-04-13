extends Area2D


@export var target: Node2D

var door_cooldown := 0.0


func _physics_process(delta: float) -> void:
	door_cooldown -= delta


func receive_interact() -> void:
	if door_cooldown > 0.0: return
	door_cooldown = 1.0
	Game.start_door_transition(target.global_position)


func _on_body_exited(body:Node2D) -> void:
	$Hint.hide()


func _on_body_entered(body:Node2D) -> void:
	$Hint.show()

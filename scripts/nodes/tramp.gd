class_name Tramp extends Area2D


@export var normal_height := 32.0
@export var pound_height := 64.0


func _on_body_entered(body:Node2D) -> void:
	if body is not PlayerCharacter: return
	
	SFX.event(&"tramp_bounce").at(self).play()
	$AnimationPlayer.stop()
	$AnimationPlayer.play(&"bounce")
	
	if body.velocity.y < 0.0: return
	
	if body.state == PlayerCharacter.State.Pound or body.last_state == PlayerCharacter.State.Pound:
		body.velocity.y = -Math.jump_velocity(pound_height, Global.gravity)
	else:
		body.velocity.y = -Math.jump_velocity(normal_height, Global.gravity)
	
	body.airborne_refresh()
	
	body.position.y = position.y - 9.0

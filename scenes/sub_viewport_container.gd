extends SubViewportContainer

@export var playerAnime: Node2D

@export var flipplayer : AnimationPlayer
@export var sprite : Sprite3D
var flip : float = 1.0

func _process(delta: float) -> void:
	var tagetrotation = (1-flip)*180
	#tween.tween_property(sprite, "rotation:y", tagetrotation, .24)
	sprite.rotation_degrees.y = lerp_angle(sprite.rotation_degrees.y, tagetrotation, Math.smooth(10,delta))

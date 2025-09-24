extends Node2D

@export var shoot_position: Marker2D
@export var hand_sprite: Sprite2D

func _process(_delta: float) -> void:
	pass

func get_shoot_position() -> Vector2:
	return shoot_position.global_position if shoot_position else global_position

func get_shoot_direction() -> Vector2:
	return Vector2.RIGHT.rotated(global_rotation)

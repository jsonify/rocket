extends Node3D

@export var target: Node3D
@export var body_rotation_speed: float = 2.0
@export var head_rotation_speed: float = 2.0

@onready var body: Node3D = $Body
@onready var head: Node3D = $Body/Head

func _process(delta: float) -> void:
	if target:
		# Rotate the body (Y-axis rotation)
		var body_direction = global_position.direction_to(target.global_position)
		var body_target_rotation = atan2(body_direction.x, body_direction.z)
		body.rotation.y = lerp_angle(body.rotation.y, body_target_rotation, body_rotation_speed * delta)
		
		# Rotate the head (X-axis rotation)
		var local_target_position = body.to_local(target.global_position)
		var head_target_rotation = atan2(-local_target_position.y, local_target_position.z)
		head.rotation.x = lerp_angle(head.rotation.x, head_target_rotation, head_rotation_speed * delta)

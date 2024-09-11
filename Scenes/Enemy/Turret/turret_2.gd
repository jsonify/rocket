extends Node3D

@export var target: Node3D
@export var body_rotation_speed: float = 2.0
@export var head_rotation_speed: float = 2.0
@export var fire_rate: float = 0.2

@onready var body: Node3D = $Body
@onready var head: Node3D = $Body/Head
@onready var marker_3d: Marker3D = %Marker3D

const TURRET_BULLET = preload("res://Scenes/Enemy/Turret/turret_bullet.tscn")
const EXPLOSION = preload("res://Scenes/explosion.tscn")

var is_player_in_range: bool = false
var can_fire: bool = true

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
	
	if is_player_in_range and can_fire:
		fire()

func fire():
	var turret_bullet_instance = TURRET_BULLET.instantiate()
	get_tree().current_scene.add_child(turret_bullet_instance)
	turret_bullet_instance.global_transform = marker_3d.global_transform
	
	# Calculate the direction to the target
	var direction_to_target = (target.global_position - marker_3d.global_position).normalized()
	
	# Set the bullet's direction
	turret_bullet_instance.set_direction(direction_to_target)
	
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _on_danger_area_3d_body_entered(body: Node3D) -> void:
	print("Body entered danger area: ", body.name)
	if body == target:
		is_player_in_range = true
		print("Player entered danger area")

func _on_danger_area_3d_body_exited(body: Node3D) -> void:
	print("Body exited danger area: ", body.name)
	if body == target:
		is_player_in_range = false
		print("Player exited danger area")

func _on_hurt_box_body_entered(body: Node3D) -> void:
	if body is Bullet:
		GameManager.increment_enemy_count()
		queue_free()
		var explode_instance = EXPLOSION.instantiate() as Node3D
		explode_instance.global_transform = global_transform
		get_tree().root.add_child(explode_instance)

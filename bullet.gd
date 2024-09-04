extends Node3D
class_name Bullet

@export var speed := 50.0
@export var lifetime := 5.0
@export_enum("X", "Y", "Z", "-X", "-Y", "-Z") var travel_axis := "X"

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var booster_particles: GPUParticles3D = $BoosterParticles

var velocity: Vector3

func _ready() -> void:
	velocity = get_travel_direction() * speed
	
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	ray_cast_3d.target_position = velocity * delta
	ray_cast_3d.force_raycast_update()
	
	if ray_cast_3d.is_colliding():
		var collision_point = ray_cast_3d.get_collision_point()
		global_position = collision_point
		on_collision()
	else:
		global_position += velocity * delta

func on_collision() -> void:
	mesh_instance_3d.visible = false
	booster_particles.emitting = true
	set_physics_process(false)  # Stop moving
	await get_tree().create_timer(1.0).timeout
	queue_free()

func get_travel_direction() -> Vector3:
	match travel_axis:
		"X": return global_transform.basis.x
		"Y": return global_transform.basis.y
		"Z": return global_transform.basis.z
		"-X": return -global_transform.basis.x
		"-Y": return -global_transform.basis.y
		"-Z": return -global_transform.basis.z
		_: return global_transform.basis.x  # Default to X if invalid input

extends CharacterBody3D
class_name Bullet

#signal enemy_hit(enemy)

@export var speed := 50.0
@export var lifetime := 5.0
@export_enum("X", "Y", "Z", "-X", "-Y", "-Z") var travel_axis := "X"

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var booster_particles: GPUParticles3D = $BoosterParticles


func _ready() -> void:
	velocity = get_travel_direction() * speed
	
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:

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


#func _on_enemy_hit(enemy: Variant) -> void:
	#print("hit enemy")
	##enemy_hit.emit()
	#mesh_instance_3d.visible = false
	#booster_particles.emitting = true
	#set_physics_process(false)  # Stop moving
	#await get_tree().create_timer(1.0).timeout
	#queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	print(body.name)
	mesh_instance_3d.visible = false
	booster_particles.emitting = true
	set_physics_process(false)  # Stop moving
	await get_tree().create_timer(1.0).timeout
	queue_free()

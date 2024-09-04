extends Node3D

class_name Bullet

@export var speed := 50.0
@export var lifetime := 5.0
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var booster_particles: GPUParticles3D = $BoosterParticles

var velocity: Vector3

func _ready() -> void:
	velocity = global_transform.basis.x * speed
	
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

#func _process(delta: float) -> void:
	#position += transform.basis.x * Vector3(speed, 0, 0)
func _physics_process(delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + velocity * delta)
	query.collide_with_areas = true
	query.collision_mask = 2  # This should match the layer you set for the target's Area3D

	var result = space_state.intersect_ray(query)
	
	if ray_cast_3d.is_colliding():
		mesh_instance_3d.visible = false
		booster_particles.emitting = true
		await get_tree().create_timer(1.0).timeout
		queue_free()
		
	#if result:
		#var collider = result.collider
		#if collider is Area3D and collider.get_parent().is_in_group("object"):
			#if collider.get_parent().has_method("hit"):
				#collider.get_parent().hit()
			#print("Bullet hit target: ", collider.get_parent().name)
			#queue_free()
		#else:
			#print("Bullet hit something else: ", collider.name)
	
	global_position += velocity * delta


func _on_timer_timeout() -> void:
	queue_free()

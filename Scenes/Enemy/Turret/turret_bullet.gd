extends CharacterBody3D

@export var speed: float = 10.0
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD

func _ready():
	# Start the lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta):
	# Move the bullet
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		_on_collision(collision)

func set_direction(new_direction: Vector3):
	# Set the bullet's direction
	direction = new_direction.normalized()
	look_at(global_position + direction)

func _on_collision(collision: KinematicCollision3D):
	var collider = collision.get_collider()
	
	# Check if the collider is a Player
	if collider is Player:
		collider.crash_sequence()
	
	# Destroy the bullet
	queue_free()

extends RigidBody3D

## How much vertical force to apply when moving.
@export_range(750.0, 3500.0) var thrust := 1000.0
@export var torque_thrust := 100.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("boost"):
		apply_central_force(basis.y * delta * thrust)
	
	if Input.is_action_pressed("rotate_left"):
		apply_torque(Vector3(0.0, 0.0, torque_thrust * delta))
	
	if Input.is_action_pressed("rotate_right"):
		apply_torque(Vector3(0.0, 0.0, -torque_thrust * delta))
	
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func _on_body_entered(body: Node) -> void:
	if "Goal" in body.get_groups():
		print("Winner Winner Chicken Dinner!!")
		
	if "Hazard" in body.get_groups():
		get_tree().reload_current_scene()
		print("YOU LOST IT!")

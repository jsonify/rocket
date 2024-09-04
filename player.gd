class_name Player extends RigidBody3D

@export_range(750.0, 3500.0) var thrust := 1000.0
@export var torque_thrust := 100.0
@export var rotor_speed := 5.0

@onready var rocket_audio: AudioStreamPlayer3D = $RocketAudio

@onready var helicoptor_body: Node3D = $HelicoptorBody
@onready var rotor: Node3D = $HelicoptorBody/Rotor
@onready var bullet_spawn: Marker3D = $HelicoptorBody/BulletSpawn
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_3d: Camera3D = $CameraMount/Camera3D

var is_transitioning := false
var rotors_active := false
var initial_rotor_y_rotation: float
var can_restart_rotor := true

# Camera zoom variables
@export var zoom_in_fov := 60.0  # Adjust this value for closer zoom
@export var zoom_out_fov := 90.0  # Adjust this value for wider zoom
@export var zoom_speed := 2.0  # Adjust this value to change zoom speed
var current_fov := zoom_in_fov

# Camera position offset
var camera_offset := Vector3(0, 2, 5)  # Adjust these values to position the camera
var initial_camera_rotation: Basis

var bullet_scene = preload("res://bullet.tscn")
@export var fire_rate := 0.2
var can_fire := true

func _ready():
	initial_rotor_y_rotation = rotor.rotation.y
	initial_camera_rotation = camera_3d.global_transform.basis
	current_fov = camera_3d.fov

func _process(delta: float) -> void:
	if rotors_active:
		rotate_rotors(delta)
		
	handle_input(delta)
	handle_camera_zoom(delta)
	update_camera_position()

func update_camera_position():
	# Calculate the camera position based on the helicopter's current orientation
	var rotated_offset = global_transform.basis * camera_offset
	var new_camera_position = global_position + rotated_offset

	# Update the camera's global position
	camera_3d.global_position = new_camera_position

	# Lock the camera's rotation to its initial state
	camera_3d.global_transform.basis = initial_camera_rotation

	# Make the camera look at a point slightly above the helicopter
	var look_target = global_position + global_transform.basis.y * 1.5
	camera_3d.look_at(look_target, Vector3.UP)

func handle_input(delta):
	# thrust
	if Input.is_action_pressed("thrust"):
		if can_restart_rotor and not rotors_active:
			start_rotor()
		apply_central_force(basis.y * delta * thrust)
	
	# reverse direction
	if Input.is_action_just_pressed("reverse_direction"):
		reverse_helicopter()
	
	# backwards
	if Input.is_action_pressed("backwards"):
		apply_torque(Vector3(0.0, 0.0, torque_thrust * delta))


	# forward
	if Input.is_action_pressed("forward"):
		apply_torque(Vector3(0.0, 0.0, -torque_thrust * delta))


	# fire bullet
	if Input.is_action_pressed("fire") and can_fire:
		shoot()
		
	# restart level
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	
func shoot():
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.global_transform = bullet_spawn.global_transform
	get_tree().root.add_child(bullet_instance)

	# Apply a small force to the helicopter in the opposite direction of the shot
	apply_central_impulse(-bullet_spawn.global_transform.basis.z * 5)

	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
	
var is_reversed := false

func rotate_rotors(delta: float):
	rotor.rotate_y(delta * rotor_speed)

func reverse_helicopter():
	is_reversed = not is_reversed
	var target_rotation = PI if is_reversed else 0
	var tween = create_tween()
	tween.tween_property(helicoptor_body, "rotation:y", target_rotation, 0.5)

func stop_rotors(delta):
	pass

func _on_body_entered(body: Node) -> void:
	if not is_transitioning:
		if "Goal" in body.get_groups():
			complete_level(body.file_path)
		if "Hazard" in body.get_groups():
			crash_sequence()
		if "SafeLanding" in body.get_groups():
			land()

func crash_sequence():
	print("YOU LOST IT!")
	helicoptor_body.visible = false
	set_process(false)
	is_transitioning = true
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(get_tree().reload_current_scene)

func complete_level(next_level_file: String):
	print("Level Complete")
	set_process(false)
	is_transitioning = true
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(get_tree().change_scene_to_file.bind(next_level_file))

func land():
	if rotor.rotation.y != 0:
		var tween = create_tween()
		tween.tween_property(self, "rotor_speed", 0, 1.0)
		tween.tween_callback(func():
			rotors_active = false
			can_restart_rotor = true
		)

func start_rotor():
	rotors_active = true
	can_restart_rotor = false
	var tween = create_tween()
	tween.tween_property(self, "rotor_speed", 25.0, 0.5) 

func handle_camera_zoom(delta):
	var target_fov = zoom_out_fov if Input.is_action_pressed("thrust") else zoom_in_fov
	camera_3d.fov = move_toward(current_fov, target_fov, zoom_speed * delta)
	camera_3d.fov = current_fov

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

# Camera variables
@export_group("Camera")
@export var zoom_in_fov := 60.0  # Closer zoom when landed
@export var zoom_out_fov := 100.0  # Wider zoom when in flight
@export var zoom_duration := 1.0  # Duration of the zoom transition in seconds
@export var zoom_height_threshold := 2.0  # Height at which to switch FOV
@export var camera_distance := 10.0
@export var camera_height := 5.0
var current_fov := zoom_in_fov
var fov_transition_timer := 0.0
var fov_start := zoom_in_fov
var fov_target := zoom_in_fov

# Camera position offset
var camera_offset := Vector3(0, 2, 5)  # Adjust these values to position the camera
var initial_camera_rotation: Basis

var bullet_scene = preload("res://bullet.tscn")
@export var fire_rate := 0.2
var can_fire := true

func _ready():
	initial_rotor_y_rotation = rotor.rotation.y
	initial_camera_rotation = camera_3d.global_transform.basis
	current_fov = zoom_in_fov
	camera_3d.fov = current_fov

func _process(delta: float) -> void:
	if rotors_active:
		rotate_rotors(delta)
		
	handle_input(delta)
	handle_camera_zoom(delta)
	update_camera_position()

func update_camera_position():
	# Calculate the desired camera position
	camera_offset = Vector3(0, camera_height, camera_distance)
	var target_position = global_position + camera_offset

	# Smoothly interpolate the camera's position
	camera_3d.global_position = camera_3d.global_position.lerp(target_position, 0.1)

	# Make the camera look at the helicopter
	camera_3d.look_at(global_position, Vector3.UP)
	
#func update_camera_position():
	## Calculate the camera position based on the helicopter's current orientation
	#var rotated_offset = global_transform.basis * camera_offset
	#var new_camera_position = global_position + rotated_offset
#
	## Update the camera's global position
	#camera_3d.global_position = new_camera_position
#
	## Lock the camera's rotation to its initial state
	#camera_3d.global_transform.basis = initial_camera_rotation
#
	## Make the camera look at a point slightly above the helicopter
	#var look_target = global_position + global_transform.basis.y * 1.5
	#camera_3d.look_at(look_target, Vector3.UP)

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
	if is_transitioning:
		return

	match true:
		_ when body.is_in_group("Goal"):
			complete_level(body.file_path)
		_ when body.is_in_group("Hazard"):
			crash_sequence()
		_ when body.is_in_group("SafeLanding"):
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

func start_rotor():
	rotors_active = true
	can_restart_rotor = false
	var tween = create_tween()
	tween.tween_property(self, "rotor_speed", 25.0, 0.5)
	print("Rotors started. Rotors Active: ", rotors_active)

func land():
	if rotor.rotation.y != 0:
		var tween = create_tween()
		tween.tween_property(self, "rotor_speed", 0, 1.0)
		tween.tween_callback(func():
			rotors_active = false
			can_restart_rotor = true
			print("Helicopter landed. Rotors Active: ", rotors_active)
		)

func handle_camera_zoom(delta):
	var new_target_fov = zoom_out_fov if position.y > zoom_height_threshold else zoom_in_fov
	
	if new_target_fov != fov_target:
		fov_target = new_target_fov
		fov_start = current_fov
		fov_transition_timer = 0.0
	
	if fov_start != fov_target:
		fov_transition_timer += delta
		var t = clamp(fov_transition_timer / zoom_duration, 0.0, 1.0)
		var ease_t = ease_in_out(t)
		current_fov = lerp(fov_start, fov_target, ease_t)
		camera_3d.fov = current_fov
		
		if t >= 1.0:
			fov_start = fov_target
			fov_transition_timer = 0.0
		
func ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

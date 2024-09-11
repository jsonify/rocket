class_name Player extends RigidBody3D

signal player_died

const BULLET = preload("res://Scenes/Player/bullet2.tscn")
const EXPLOSION = preload("res://Scenes/explosion.tscn")

@export_range(750.0, 3500.0) var thrust := 1000.0
@export var torque_thrust := 100.0
@export var rotor_speed := 5.0
@export var flip_force := 20.0
@export var fire_rate := 0.2

@export_group("Camera")
@export var zoom_in_fov := 45.0
@export var zoom_out_fov := 105.0
@export var zoom_duration := 1.5
@export var camera_distance := 10.0
@export var camera_height := 5.0

@onready var rocket_audio: AudioStreamPlayer3D = $RocketAudio
@onready var helicoptor_body: Node3D = $HelicoptorBody
@onready var rotor: Node3D = $HelicoptorBody/Rotor
@onready var bullet_spawn: Marker3D = $HelicoptorBody/BulletSpawn
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_3d: Camera3D = $CameraMount/Camera3D

var gas_level: float
var is_transitioning := false
var rotors_active := false
var initial_rotor_y_rotation: float
var can_restart_rotor := true
var stopwatch_started := false
var is_flipping := false
var flip_timer := 0.0
var is_reversed := false
var has_crashed := false
var can_fire := true

var camera_offset := Vector3(0, 2, 5)
var is_in_wide_fov_area := false
var target_fov := zoom_in_fov
var current_fov := zoom_in_fov
var fov_tween: Tween

func _ready():
	add_to_group("Player")
	gas_level = GasManager.current_gas_level
	initial_rotor_y_rotation = rotor.rotation.y
	current_fov = zoom_in_fov
	target_fov = zoom_in_fov
	camera_3d.fov = current_fov
	print("Initial FOV set to: ", current_fov)
	call_deferred("initial_camera_setup")

func _physics_process(delta: float) -> void:
	if has_crashed:
		return
	gas_level = GasManager.current_gas_level
	if rotors_active:
		rotate_rotors(delta)
	handle_input(delta)
	update_camera_zoom(delta)
	update_camera_position()

func initial_camera_setup():
	if camera_3d and is_inside_tree():
		update_camera_position()

func handle_input(delta):
	if Input.is_action_pressed("thrust"):
		handle_thrust(delta)
	if Input.is_action_just_pressed("reverse_direction"):
		reverse_helicopter()
	if Input.is_action_pressed("backwards"):
		apply_torque(Vector3(0.0, 0.0, torque_thrust * delta))
	if Input.is_action_pressed("forward"):
		apply_torque(Vector3(0.0, 0.0, -torque_thrust * delta))
	if Input.is_action_pressed("fire") and can_fire:
		shoot()

func handle_thrust(delta):
	if gas_level > 0:
		GasManager.reduce_gas_level()
		if can_restart_rotor and not rotors_active:
			start_rotor()
		if not stopwatch_started:
			start_stopwatch()
		apply_central_force(basis.y * delta * thrust)
	else:
		crash_sequence()

func rotate_rotors(delta: float):
	rotor.rotate_y(delta * rotor_speed)

func reverse_helicopter():
	is_reversed = not is_reversed
	var target_rotation := PI if is_reversed else 0.0
	var tween = create_tween()
	tween.tween_property(helicoptor_body, "rotation:y", target_rotation, 0.5)

func start_rotor():
	rotors_active = true
	can_restart_rotor = false
	var tween = create_tween()
	tween.tween_property(self, "rotor_speed", 25.0, 0.5)

func start_stopwatch():
	if not stopwatch_started:
		GameManager.start_stopwatch()
		stopwatch_started = true

func shoot():
	var bullet_instance = BULLET.instantiate()
	bullet_instance.global_transform = bullet_spawn.global_transform
	get_tree().root.add_child(bullet_instance)
	apply_central_impulse(-bullet_spawn.global_transform.basis.z * 5)
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func update_camera_position():
	if not is_inside_tree() or not camera_3d.is_inside_tree() or has_crashed:
		return
	camera_offset = Vector3(0, camera_height, camera_distance)
	var target_position = global_position + camera_offset
	camera_3d.global_position = camera_3d.global_position.lerp(target_position, 0.1)
	camera_3d.look_at_from_position(camera_3d.global_position, global_position, Vector3.UP)

func update_camera_zoom(delta):
	if current_fov != target_fov:
		print("Zooming camera. Current FOV: ", current_fov, " Target FOV: ", target_fov)
		var new_fov = lerp(current_fov, target_fov, delta / zoom_duration)
		camera_3d.fov = new_fov
		current_fov = new_fov
		if abs(current_fov - target_fov) < 0.01:
			current_fov = target_fov
			camera_3d.fov = current_fov
			print("FOV zoom completed. New FOV: ", current_fov)

func zoom_camera(new_target_fov: float):
	if fov_tween:
		fov_tween.kill()
	fov_tween = create_tween()
	fov_tween.tween_property(camera_3d, "fov", new_target_fov, zoom_duration)
	fov_tween.tween_callback(func(): 
		current_fov = new_target_fov
		print("FOV zoom completed. New FOV: ", current_fov)
	)

func enter_wide_fov_area():
	print("Entering wide FOV area")
	is_in_wide_fov_area = true
	target_fov = zoom_out_fov
	zoom_camera(target_fov)

func exit_wide_fov_area():
	print("Exiting wide FOV area")
	is_in_wide_fov_area = false
	target_fov = zoom_in_fov
	zoom_camera(target_fov)

func _on_body_entered(body: Node) -> void:
	if is_transitioning:
		return
	match true:
		_ when body.is_in_group("Goal"):
			complete_level()
		_ when body.is_in_group("Hazard"):
			crash_sequence()
		_ when body.is_in_group("SafeLanding"):
			land()

func crash_sequence():
	if has_crashed:
		return
	has_crashed = true
	set_physics_process(false)
	freeze = true
	camera_mount.set_as_top_level(true)
	camera_3d.set_as_top_level(true)
	var explode_instance = EXPLOSION.instantiate() as Node3D
	explode_instance.global_transform = global_transform
	get_tree().root.add_child(explode_instance)
	helicoptor_body.visible = false
	player_died.emit()
	complete_level()

func complete_level():
	set_process(false)
	GameManager.stop_stopwatch()

func auto_next_level(input: bool, next_level_file: String = ""):
	if not input or next_level_file.is_empty():
		return
	is_transitioning = true
	var tween = create_tween()
	tween.tween_interval(2)
	tween.tween_callback(get_tree().change_scene_to_file.bind(next_level_file))

func land():
	if rotor.rotation.y != 0:
		var tween = create_tween()
		tween.tween_property(self, "rotor_speed", 0, 0.0)
		tween.tween_callback(func():
			rotors_active = false
			can_restart_rotor = true
			GameManager.stop_stopwatch()
		)

func _on_hurtbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		print("Enemy entered")

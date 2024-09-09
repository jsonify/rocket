class_name Player extends RigidBody3D

#signal player_died
#signal player_landed  # New signal for landing

@export_range(750.0, 3500.0) var thrust := 1000.0
@export var torque_thrust := 100.0
@export var rotor_speed := 5.0
@export var flip_force := 20.0

@onready var rocket_audio: AudioStreamPlayer3D = $RocketAudio
@onready var helicoptor_body: Node3D = $HelicoptorBody
@onready var rotor: Node3D = $HelicoptorBody/Rotor
@onready var bullet_spawn: Marker3D = $HelicoptorBody/BulletSpawn
@onready var camera_mount: Node3D = $CameraMount
@onready var camera_3d: Camera3D = $CameraMount/Camera3D

const BULLET = preload("res://Scenes/Player/bullet2.tscn")
const EXPLOSION = preload("res://Scenes/explosion.tscn")

var is_transitioning := false
var rotors_active := false
var initial_rotor_y_rotation: float
var can_restart_rotor := true
var stopwatch_started := false
var is_flipping := false
var flip_timer := 0.0
var is_reversed := false

var gas_level : float

# Camera variables
@export_group("Camera")
@export var zoom_in_fov := 60.0
@export var zoom_out_fov := 100.0
@export var zoom_duration := 1.0
@export var zoom_height_threshold := 2.0
@export var camera_distance := 10.0
@export var camera_height := 5.0
var current_fov := zoom_in_fov
var fov_transition_timer := 0.0
var fov_start := zoom_in_fov
var fov_target := zoom_in_fov

var camera_offset := Vector3(0, 2, 5)
@export var fire_rate := 0.2
var can_fire := true

var has_crashed := false
var crash_camera_transform: Transform3D
var initial_camera_rotation: Basis
var initial_camera_mount_transform: Transform3D

func _ready():
	gas_level = GasManager.current_gas_level
	initial_camera_mount_transform = camera_mount.transform
	
	if camera_3d:
		print("Player: Camera3D node found")
		initial_rotor_y_rotation = rotor.rotation.y
		current_fov = zoom_in_fov
		camera_3d.fov = current_fov
	else:
		print("Player: Camera3D node not found")
	
	call_deferred("initial_camera_setup")


func initial_camera_setup():
	if camera_3d and is_inside_tree():
		update_camera_position()

func _physics_process(delta: float) -> void:
	print("processing camera_3d.rotation.z: ", camera_3d.rotation.z)
	if has_crashed:
		return
	gas_level = GasManager.current_gas_level
	if rotors_active:
		rotate_rotors(delta)
	
	if is_flipping:
		apply_flip_force(delta)
	else:
		check_upside_down()
		handle_input(delta)
	
	handle_camera_zoom(delta)
	update_camera_position()
	
	if is_inside_tree():
		update_camera_position()


func check_upside_down():
	if helicoptor_body.global_transform.basis.y.dot(Vector3.UP) < -0.5:
		start_flip()

func start_flip():
	is_flipping = true
	flip_timer = 0.0

func apply_flip_force(delta: float):
	flip_timer += delta
	if flip_timer > 1.0:
		var up_dot = helicoptor_body.global_transform.basis.y.dot(Vector3.UP)
		
		if up_dot < 0.9:
			var flip_strength = flip_force * (1.0 - up_dot) * 0.5
			var flip_direction = 1 if up_dot < 0 else -1
			apply_torque(Vector3.BACK * flip_strength * flip_direction)
		else:
			is_flipping = false
			flip_timer = 0.0
			angular_velocity = Vector3.ZERO

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
	
	#bullet_instance.enemy_hit.connect(_on_bullet_hit_enemy)
	
	apply_central_impulse(-bullet_spawn.global_transform.basis.z * 5)
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _on_bullet_hit_enemy(enemy):
	enemy.queue_free()

func update_camera_position():
	if not is_inside_tree() or not camera_3d.is_inside_tree():
		return
	
	if has_crashed:
		return  # Don't update camera if crashed
	
	camera_mount.transform = camera_mount.transform.interpolate_with(initial_camera_mount_transform, 0.1)
	
	camera_offset = Vector3(0, camera_height, camera_distance)
	var target_position = camera_mount.to_global(camera_offset)
	camera_3d.global_position = camera_3d.global_position.lerp(target_position, 0.1)
	camera_3d.look_at(global_position, Vector3.UP)

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

func _on_body_entered(body: Node) -> void:
	if is_transitioning:
		return

	match true:
		_ when body.is_in_group("Goal"):
			complete_level()
		_ when body.is_in_group("Hazard"):
			crash_sequence()

func crash_sequence():
	if has_crashed:
		return  # Prevent multiple calls
	
	has_crashed = true
	set_physics_process(false)
	RigidBody3D.FREEZE_MODE_STATIC  # Freeze the player's physics

	# Freeze the camera mount and camera
	camera_mount.set_as_top_level(true)
	camera_3d.set_as_top_level(true)

	print("Camera rotation at crash (radians): ", camera_3d.rotation)
	print("Camera rotation at crash (degrees): ", camera_3d.rotation_degrees)

	var explode_instance = EXPLOSION.instantiate() as Node3D
	explode_instance.global_transform = global_transform
	get_tree().root.add_child(explode_instance)
	
	helicoptor_body.visible = false
	complete_level()


func complete_level():
	set_process(false)
	GameManager.stop_stopwatch()

func _on_hurtbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		print("Enemy entered")

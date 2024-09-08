class_name Ring extends Node3D

#signal ring_success
signal ring_failure

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var success_area_3d: Area3D = $SuccessArea3D
@onready var fail_area_3d: Area3D = $FailArea3D

var original_material: StandardMaterial3D
var is_triggered := false

func _ready():
	# Create a new StandardMaterial3D
	original_material = StandardMaterial3D.new()
	
	# Set the albedo color to gold
	original_material.albedo_color = Color(1.0, 0.843, 0.0, 1.0)  # RGB values for gold
	
	# Set metallic and roughness properties for a shiny appearance
	original_material.metallic = 0.8
	original_material.roughness = 0.2
	
	# Set emission for a slight glow effect
	original_material.emission_enabled = true
	original_material.emission = Color(0.5, 0.4, 0.0)  # Subtle gold emission
	original_material.emission_energy = 0.5
	
	# Set transparency mode
	original_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply the material to the MeshInstance3D
	if mesh_instance:
		mesh_instance.material_override = original_material
	else:
		print("Error: MeshInstance3D not found")

	# Connect signals only if they're not already connected
	if not success_area_3d.body_exited.is_connected(_on_success_area_3d_body_exited):
		success_area_3d.body_exited.connect(_on_success_area_3d_body_exited)
	if not fail_area_3d.body_entered.is_connected(_on_fail_area_3d_body_entered):
		fail_area_3d.body_entered.connect(_on_fail_area_3d_body_entered)

func set_mesh_color(new_color: Color):
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.albedo_color = new_color
		# Reset metallic and roughness for non-metallic appearance
		material.metallic = 0.0
		material.roughness = 1.0
		# Disable emission for non-metallic colors
		material.emission_enabled = false
	else:
		print("Error: Material not found")

func _on_success_area_3d_body_exited(body: Node3D) -> void:
	if not is_triggered:
		is_triggered = true
		set_mesh_color(Color(0.0, 1.0, 0.0))  # Set to green, fully opaque
		fail_area_3d.monitoring = false
		GameManager.increment_ring_count()
		ring_success.emit()
		fade_out()

func _on_fail_area_3d_body_entered(body: Node3D) -> void:
	if not is_triggered:
		is_triggered = true
		set_mesh_color(Color(1.0, 0.0, 0.0))  # Set to red, fully opaque
		success_area_3d.monitoring = false
		ring_failure.emit()
		fade_out()

func fade_out():
	var tween = create_tween()
	tween.tween_method(set_alpha, 1.0, 0.0, 1.0)
	tween.tween_callback(queue_free)

func set_alpha(value: float):
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		var current_color = material.albedo_color
		material.albedo_color = Color(current_color.r, current_color.g, current_color.b, value)
	else:
		print("Error: Material not found")

extends Node3D

@onready var area_3d: Area3D = $Box/AreaBody3D

func _ready() -> void:
	add_to_group("object")
	
	if area_3d:
		# Ensure the Area3D is on the correct collision layer (e.g., layer 2)
		area_3d.collision_layer = 2
		area_3d.collision_mask = 0  # It doesn't need to detect anything
		print("Area3D configured for raycast detection")
	else:
		push_error("No Area3D found in the Target scene. Collision detection will not work.")

func hit():
	print("Target hit!")
	queue_free()

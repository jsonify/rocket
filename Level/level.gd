class_name Level extends Node3D


func _ready():
	GameManager.set_total_rings(0)  # Replace 0 with the actual number of rings in the level
	GameManager.reset_game_state()

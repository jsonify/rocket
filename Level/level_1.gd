class_name Level1 extends Level

signal entry_entered

func _ready():
	GameManager.reset_game_state()


func _on_entry_area_3d_1_body_entered(body: Node3D) -> void:
	#if body.has_signal("player_entered"):
		#entry_entered.emit()
		#print("found the signal")
	if body.is_in_group("Player"):
		print("entering area now")
		body.enter_wide_fov_area()


func _on_entry_area_3d_1_body_exited(body: Node3D) -> void:
		if body.is_in_group("Player"):
			print("exiting area now")
			
			body.exit_wide_fov_area()

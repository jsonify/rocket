extends Level

func _ready():
	print("Level 1 loaded")
	GameManager.set_total_rings(7)
	GameManager.reset_game_state()
	print("Level 1 setup complete. Total rings: ", GameManager.total_rings)

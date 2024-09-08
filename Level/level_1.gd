extends Level

func _ready():
	GameManager.set_total_rings(7)
	GameManager.reset_game_state()

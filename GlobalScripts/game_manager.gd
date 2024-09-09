extends Node

#signal ring_count_changed(new_count: int)
signal enemy_count_changed(new_count: int)
signal stopwatch_updated(time: float)
signal score_updated(new_score: int)
signal game_finished

var enemy_count: int = 0
#var total_rings: int = 0
var stopwatch_time: float = 0.0
var stopwatch_running: bool = false
var current_score: int = 0

func _process(delta):
	if stopwatch_running:
		stopwatch_time += delta
		emit_signal("stopwatch_updated", stopwatch_time)

func increment_enemy_count():
	enemy_count += 1
	emit_signal("enemy_count_changed", enemy_count)
	update_score()

func start_stopwatch():
	stopwatch_running = true

func stop_stopwatch():
	stopwatch_running = false
	update_score()
	emit_signal("game_finished")

func update_score():
	var enemy_score = enemy_count * 1000

	var time_factor = 1.0 if stopwatch_time == 0 else 1.0 + (0.1 / stopwatch_time)
	current_score = int(enemy_score * time_factor)
	emit_signal("score_updated", current_score)
	#print("GameManager: Score updated - ", current_score)

func reset_game_state():
	enemy_count = 0
	stopwatch_time = 0.0
	stopwatch_running = false
	current_score = 0
	emit_signal("enemy_count_changed", enemy_count)
	emit_signal("stopwatch_updated", stopwatch_time)
	emit_signal("score_updated", current_score)
	GasManager.current_gas_level = 100

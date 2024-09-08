extends Node

signal ring_count_changed(new_count: int)
signal stopwatch_updated(time: float)
signal score_updated(new_score: int)
signal game_finished

var ring_count: int = 0
var total_rings: int = 0
var stopwatch_time: float = 0.0
var stopwatch_running: bool = false
var current_score: int = 0

func _ready():
	print("GameManager: Ready")

func _process(delta):
	if stopwatch_running:
		stopwatch_time += delta
		emit_signal("stopwatch_updated", stopwatch_time)
		print("GameManager: Stopwatch updated - ", stopwatch_time)

func increment_ring_count():
	ring_count += 1
	emit_signal("ring_count_changed", ring_count)
	print("GameManager: Ring count changed - ", ring_count)
	update_score()

func set_total_rings(count: int):
	total_rings = count
	print("GameManager: Total rings set - ", total_rings)

func start_stopwatch():
	stopwatch_running = true
	print("GameManager: Stopwatch started")

func stop_stopwatch():
	stopwatch_running = false
	update_score()
	emit_signal("game_finished")
	print("GameManager: Stopwatch stopped, game finished")

func update_score():
	var ring_score = ring_count * 1000
	if ring_count == total_rings:
		ring_score *= 1.5
	var time_factor = 1.0 if stopwatch_time == 0 else 1.0 + (0.1 / stopwatch_time)
	current_score = int(ring_score * time_factor)
	emit_signal("score_updated", current_score)
	print("GameManager: Score updated - ", current_score)

func reset_game_state():
	ring_count = 0
	stopwatch_time = 0.0
	stopwatch_running = false
	current_score = 0
	emit_signal("ring_count_changed", ring_count)
	emit_signal("stopwatch_updated", stopwatch_time)
	emit_signal("score_updated", current_score)
	print("GameManager: Game state reset")

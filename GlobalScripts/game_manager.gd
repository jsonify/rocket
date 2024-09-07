extends Node

signal ring_count_changed(new_count: int)
signal stopwatch_updated(time: float)
signal score_updated(new_score: int)

var ring_count: int = 0
var total_rings: int = 0
var stopwatch_time: float = 0.0
var stopwatch_running: bool = false
var current_score: int = 0

# Scoring constants
const BASE_SCORE_PER_RING: int = 1000
const TIME_FACTOR: float = 0.1
const ALL_RINGS_BONUS: float = 1.5

func _ready():
	pass

func _process(delta):
	if stopwatch_running:
		stopwatch_time += delta
		emit_signal("stopwatch_updated", stopwatch_time)
		update_score()

func increment_ring_count():
	ring_count += 1
	emit_signal("ring_count_changed", ring_count)
	update_score()

func set_total_rings(count: int):
	total_rings = count

func start_stopwatch():
	stopwatch_running = true

func stop_stopwatch():
	stopwatch_running = false
	update_score()  # Final score update when stopping

func reset_game_state():
	ring_count = 0
	stopwatch_time = 0.0
	stopwatch_running = false
	current_score = 0
	emit_signal("ring_count_changed", ring_count)
	emit_signal("stopwatch_updated", stopwatch_time)
	emit_signal("score_updated", current_score)

func update_score():
	var ring_score = ring_count * BASE_SCORE_PER_RING
	
	# Apply bonus for collecting all rings
	if ring_count == total_rings:
		ring_score *= ALL_RINGS_BONUS
	
	# Calculate time factor (higher for faster times)
	var time_factor = 1.0
	if stopwatch_time > 0:
		time_factor = 1.0 + (TIME_FACTOR / stopwatch_time)
	
	# Calculate final score
	current_score = int(ring_score * time_factor)
	
	emit_signal("score_updated", current_score)

func get_final_score() -> int:
	return current_score

extends Node

@warning_ignore("unused_signal")
signal ring_count_changed(new_count: int)
@warning_ignore("unused_signal")
signal stopwatch_updated(time: float)

var ring_count: int = 0
var total_rings: int = 0
var stopwatch_time: float = 0.0
var stopwatch_running: bool = false

func _ready():
	pass

func _process(delta):
	if stopwatch_running:
		stopwatch_time += delta
		emit_signal("stopwatch_updated", stopwatch_time)

func increment_ring_count():
	ring_count += 1
	emit_signal("ring_count_changed", ring_count)


func set_total_rings(count: int):
	total_rings = count

func start_stopwatch():
	stopwatch_running = true

func stop_stopwatch():
	stopwatch_running = false

func reset_game_state():
	ring_count = 0
	stopwatch_time = 0.0
	stopwatch_running = false
	emit_signal("ring_count_changed", ring_count)
	emit_signal("stopwatch_updated", stopwatch_time)

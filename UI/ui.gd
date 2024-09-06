extends CanvasLayer
@onready var ring_counter_label: Label = $Control/RingsCounter/Label
@onready var stopwatch_label: Label = $Control/TimeCounter/Label

func _ready():
	GameManager.ring_count_changed.connect(_on_ring_count_changed)
	update_ring_counter(GameManager.ring_count)
	GameManager.stopwatch_updated.connect(_on_stopwatch_updated)
	update_stopwatch(0.0)

func _on_ring_count_changed(new_count: int):
	print("Ring count changed signal received. New count: ", new_count)
	update_ring_counter(new_count)

func update_ring_counter(count: int):
	var text = "%d / %d" % [count, GameManager.total_rings]
	print("Updating UI: ", text)
	ring_counter_label.text = text

func _on_stopwatch_updated(time: float):
	update_stopwatch(time)

func update_stopwatch(time: float):
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	stopwatch_label.text = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

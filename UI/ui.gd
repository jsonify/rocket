extends CanvasLayer

@onready var ring_counter_label: Label = $Control/RingCounter/Label
@onready var stopwatch_label: Label = $Control/Stopwatch/Label
@onready var score_label: Label = $Control/ScoreLabel/Label

func _ready():
	GameManager.ring_count_changed.connect(_on_ring_count_changed)
	GameManager.stopwatch_updated.connect(_on_stopwatch_updated)
	GameManager.score_updated.connect(_on_score_updated)
	update_ring_counter(0)
	update_stopwatch(0.0)
	update_score(0)

func _on_ring_count_changed(new_count: int):
	update_ring_counter(new_count)

func _on_stopwatch_updated(time: float):
	update_stopwatch(time)

func _on_score_updated(new_score: int):
	update_score(new_score)

func update_ring_counter(count: int):
	ring_counter_label.text = "Rings: %d / %d" % [count, GameManager.total_rings]

func update_stopwatch(time: float):
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	stopwatch_label.text = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func update_score(score: int):
	score_label.text = "Score: %d" % score

extends CanvasLayer

#@onready var ring_counter_label: Label = %RingCounter/Label
@onready var stopwatch_label: Label = $Control/Stopwatch/Label
@onready var score_label: Label = $Control/ScoreLabel/Label
@onready var score_label_node: NinePatchRect = $Control/ScoreLabel
@onready var gasbar: ProgressBar = %Gasbar
@onready var enemy_counter_label: Label = %EnemyCounter/Label


func _ready():
	GameManager.enemy_count_changed.connect(_on_enemy_count_changed)
	GameManager.stopwatch_updated.connect(_on_stopwatch_updated)
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.game_finished.connect(_on_game_finished)
	GasManager.gas_level_changed.connect(_on_gas_level_changed)
	
	#update_ring_counter(0)
	update_stopwatch(0.0)
	update_score(0)
	update_enemy_counter(0)
	
	score_label.visible = false
	score_label_node.visible = false
	#print("UI: Initial setup complete")

func _on_gas_level_changed(current_gas_level : float):
	gasbar.value = GasManager.current_gas_level

#func _on_ring_count_changed(new_count: int):
	##print("UI: Ring count changed - ", new_count)
	#update_ring_counter(new_count)

func _on_enemy_count_changed(new_count: int):
	update_enemy_counter(new_count)

func _on_stopwatch_updated(time: float):
	#print("UI: Stopwatch updated - ", time)
	update_stopwatch(time)

func _on_score_updated(new_score: int):
	#print("UI: Score updated - ", new_score)
	update_score(new_score)

func _on_game_finished():
	#print("UI: Game finished")
	score_label_node.visible = true
	score_label.visible = true

#func update_ring_counter(count: int):
	#ring_counter_label.text = "%d / %d" % [count, GameManager.total_rings]
	#print("UI: Ring counter updated - ", ring_counter_label.text)

func update_enemy_counter(count):
	enemy_counter_label.text = "%d" % [count]

func update_stopwatch(time: float):
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	stopwatch_label.text = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
	#print("UI: Stopwatch updated - ", stopwatch_label.text)

func update_score(score: int):
	score_label.text = "Score: %d" % score
	#print("UI: Score updated - ", score_label.text)

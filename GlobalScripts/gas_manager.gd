extends Node

signal gas_level_changed

var max_gas_level := 100.0
var current_gas_level : float

func _ready() -> void:
	current_gas_level = max_gas_level


func reduce_gas_level(gas_amount : float):
	current_gas_level -= gas_amount
	
	if current_gas_level < 0:
		current_gas_level = 0
	print("reduce gas level called")
	gas_level_changed.emit(current_gas_level)

func increase_gas_level(gas_amount : float):
	current_gas_level += gas_amount
	
	if current_gas_level > max_gas_level:
		current_gas_level = max_gas_level
	print("increase gas level called")
	gas_level_changed.emit(current_gas_level)
	

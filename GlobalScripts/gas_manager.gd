extends Node

signal gas_level_changed

var max_gas_level := 100.0
var current_gas_level : float

var debug := true
var gas_reduction_factor := 0.1

func _ready() -> void:
	if debug:
		gas_reduction_factor = 2
	current_gas_level = max_gas_level


func reduce_gas_level():
	current_gas_level -= gas_reduction_factor
	
	if current_gas_level < 0:
		current_gas_level = 0
	gas_level_changed.emit(current_gas_level)

func increase_gas_level(gas_amount : float):
	current_gas_level += gas_amount
	
	if current_gas_level > max_gas_level:
		current_gas_level = max_gas_level
	gas_level_changed.emit(current_gas_level)
	

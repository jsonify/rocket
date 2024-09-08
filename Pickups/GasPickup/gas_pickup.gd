extends Node3D

@export var gas_amount := 35

func _on_gas_pickup_box_body_entered(_body: Node3D) -> void:
	GasManager.increase_gas_level(gas_amount)
	queue_free()

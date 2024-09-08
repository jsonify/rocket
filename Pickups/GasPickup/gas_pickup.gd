extends Node3D

@export var pickup_amount := 35


func _on_gas_pickup_box_body_entered(body: Node3D) -> void:
	print("Got gas")
	queue_free()

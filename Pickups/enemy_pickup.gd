extends Node3D

func _on_hitbox_body_entered(body: Node3D) -> void:
	print(body.name)
	print("hit by the enemy")
	GameManager.game_finished
	


func _on_hurtbox_body_entered(body: Node3D) -> void:
	print(body.name)
	print("from enemy- hit by bullet")
	queue_free()

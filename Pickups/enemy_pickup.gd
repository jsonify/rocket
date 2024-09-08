extends Node3D

func _on_hitbox_body_entered(body: Node3D) -> void:
	print(body.name)
	print("hit by the enemy")
	


func _on_hurtbox_body_entered(body: Node3D) -> void:
	GameManager.increment_enemy_count()
	queue_free()

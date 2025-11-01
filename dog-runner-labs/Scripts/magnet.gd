extends Area3D

# Magnet power-up collectible
# When collected, gives player magnet ability for 20 seconds

signal magnet_collected

func _ready() -> void:
	# Add to collectibles group for player detection
	add_to_group("collectibles")
	
	# Connect body entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Emit signal that magnet was collected
		magnet_collected.emit()
		
		# Remove the magnet from the scene
		queue_free()

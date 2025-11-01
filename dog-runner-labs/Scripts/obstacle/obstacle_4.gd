extends CharacterBody3D

# This is a full-width 3-lane obstacle that blocks all lanes
# It should be scaled to cover all 3 lanes when spawned

func _ready() -> void:
	# Ensure it's added to the obstacles group
	add_to_group("obstacles")

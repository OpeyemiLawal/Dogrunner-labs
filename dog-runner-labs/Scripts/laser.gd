extends Node3D

@export var speed: float = 20.0  # Speed of the laser projectile
@export var damage: int = 10    # Damage dealt to player

@onready var damage_area: Area3D = $Area3D

func _ready() -> void:
	# Connect to the damage area
	if damage_area:
		damage_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Move the laser forward (in negative Z direction for the runner)
	position.z += speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Deal damage to the player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Destroy the laser projectile
		queue_free()

func _on_visible_on_screen_enabler_3d_screen_exited() -> void:
	# Destroy the laser when it goes off screen
	queue_free()

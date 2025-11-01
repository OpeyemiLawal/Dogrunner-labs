extends StaticBody3D

@onready var damage_area: Area3D = $DamageArea
@onready var hit_particles: GPUParticles3D = $HitParticles
@onready var hit_light: OmniLight3D = $HitLight
signal obstacle_hit  # For visual effects

func _ready() -> void:
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_body_entered)

func _on_damage_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Damage the player
		if body.has_method("take_damage"):
			body.take_damage(5)
		
		# Emit particles
		if hit_particles:
			hit_particles.restart()
		
		# Flash light
		if hit_light:
			var tween = create_tween()
			tween.tween_property(hit_light, "light_energy", 5.0, 0.1)
			tween.tween_property(hit_light, "light_energy", 0.0, 0.4)
		
		# Emit signal for visual effects
		obstacle_hit.emit()
		
		print("Player hit obstacle! Took 5 damage.")

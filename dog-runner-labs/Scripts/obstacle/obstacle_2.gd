extends StaticBody3D

@onready var shoot_timer: Timer = $ShootTimer
@onready var marker_3d: Marker3D = $laser/Marker3D
@onready var respawn_timer: Timer
@onready var damage_area: Area3D = $DamageArea
@export var damage = 5

func _ready() -> void:
	if shoot_timer:
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start()
	
	# Create respawn timer (not needed for new system, but keeping for compatibility)
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 2.0  # Respawn laser after 2 seconds
	respawn_timer.one_shot = true
	add_child(respawn_timer)

func _on_shoot_timer_timeout() -> void:
	shoot_laser()

func shoot_laser() -> void:
	# Instantiate the laser projectile scene
	var laser_scene = preload("res://Scene/laser.tscn")
	var laser_instance = laser_scene.instantiate()
	
	# Add to parent scene first
	get_parent().add_child(laser_instance)
	
	# Set position to Marker3D global position (now that it's in the scene tree)
	laser_instance.global_position = marker_3d.global_position


func _on_damage_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

extends Node3D

@onready var tile_mesh: MeshInstance3D = $TileMesh
@onready var pit_area: Area3D = $PitArea
@onready var fall_timer: Timer
@onready var lifetime_timer: Timer

func _ready() -> void:
	if pit_area:
		pit_area.body_entered.connect(_on_pit_body_entered)
	
	fall_timer = Timer.new()
	fall_timer.wait_time = 0.01  # Fall immediately (smallest valid time)
	fall_timer.one_shot = true
	fall_timer.timeout.connect(_fall)
	add_child(fall_timer)
	fall_timer.start()
	
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = 60.0  # Disappear after 60 seconds
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()

func _on_lifetime_timeout() -> void:
	queue_free()

func _fall() -> void:
	# Animate the tile falling
	var tween = create_tween()
	tween.tween_property(tile_mesh, "position:y", -5.0, 15.0)
	tween.tween_callback(_on_fall_complete)

func _on_fall_complete() -> void:
	# Hide the mesh to show the pit
	tile_mesh.visible = false

func _on_pit_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(5)
		if body.has_method("hit_effect"):
			body.hit_effect.emit()
		print("Player fell into pit!")

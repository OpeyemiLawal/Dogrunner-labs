extends Area3D

# $XYZ Solana Token Collectible Script

signal xyz_collected

@onready var hud = get_tree().get_first_node_in_group("hud")

var collected = false
var player_ref = null
var being_dragged = false
const DRAG_SPEED = 10.0  # Speed at which coins are dragged to player
const DRAG_RANGE = 15.0  # Range within which coins start being dragged
const COLLECTION_RANGE = 2.0  # Range at which coins are collected after being dragged
var drag_particles: GPUParticles3D = null

func _ready() -> void:
	if hud and hud.has_method("_on_xyz_collected"):
		xyz_collected.connect(hud._on_xyz_collected)
	
	# Get player reference
	player_ref = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	# Check for magnet dragging and collection
	if not collected and player_ref and player_ref.has_method("is_magnet_active") and player_ref.is_magnet_active():
		var distance = global_position.distance_to(player_ref.global_position)
		
		# Start dragging if within drag range
		if distance <= DRAG_RANGE and not being_dragged:
			being_dragged = true
			start_drag_effect()
		
		# Move towards player if being dragged
		if being_dragged:
			var direction = (player_ref.global_position - global_position).normalized()
			global_position += direction * DRAG_SPEED * delta
			
			# Check if close enough to collect
			distance = global_position.distance_to(player_ref.global_position)
			if distance <= COLLECTION_RANGE:
				collected = true
				stop_drag_effect()
				play_collection_vfx()
	
	# Regular collection check (for non-magnet gameplay)
	elif not collected and player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		if distance <= COLLECTION_RANGE:
			collected = true
			play_collection_vfx()

func start_drag_effect() -> void:
	# Create particle trail effect
	drag_particles = GPUParticles3D.new()
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.05
	particle_material.direction = Vector3(0, 0, -1)  # Trail behind the coin
	particle_material.spread = 30.0
	particle_material.gravity = Vector3(0, 0, 0)
	particle_material.initial_velocity_min = 0.5
	particle_material.initial_velocity_max = 1.5
	particle_material.scale_min = 0.02
	particle_material.scale_max = 0.05
	particle_material.color = Color(1.0, 0.9, 0.0, 0.8)  # Golden trail
	
	drag_particles.process_material = particle_material
	drag_particles.amount = 15
	drag_particles.lifetime = 0.5
	drag_particles.one_shot = false
	drag_particles.emitting = true
	
	add_child(drag_particles)

func stop_drag_effect() -> void:
	if drag_particles:
		drag_particles.emitting = false
		# Remove particles after a short delay
		var timer = Timer.new()
		timer.wait_time = 0.6
		timer.one_shot = true
		timer.timeout.connect(func(): drag_particles.queue_free())
		add_child(timer)
		timer.start()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not collected:
		collected = true
		play_collection_vfx()

func play_collection_vfx() -> void:
	# Stop the spinning animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
	
	# Create particle burst effect
	create_particle_burst()
	
	# Create scaling and fade animation
	play_collection_animation()
	
	# Emit collection signal
	xyz_collected.emit()

func create_particle_burst() -> void:
	# Create particle system for collection effect
	var particles = GPUParticles3D.new()
	
	# Configure particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.2
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	particle_material.color = Color(1.0, 0.8, 0.0, 1.0)  # $XYZ token gold color
	
	particles.process_material = particle_material
	particles.amount = 20
	particles.lifetime = 1.0  # Fixed: lifetime goes on the particles node, not material
	particles.one_shot = true
	particles.emitting = true
	
	# Position at $XYZ token center
	particles.position = Vector3(0, 0, 0)
	
	# Add to scene and auto-remove after lifetime
	get_parent().add_child(particles)
	
	# Create timer to remove particles
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	get_parent().add_child(timer)
	timer.start()

func play_collection_animation() -> void:
	# Create tween for smooth collection animation
	var tween = create_tween()
	if not tween:
		# Fallback if tween creation fails
		queue_free()
		return
		
	tween.set_parallel(true)
	
	# Scale up effect
	var scale_tween = tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
	if scale_tween:
		scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Add slight upward movement
	var move_tween = tween.tween_property(self, "position:y", position.y + 0.5, 0.3)
	if move_tween:
		move_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Note: Fade out removed for 3D models as Node3D doesn't support modulate
	
	# Wait for animation then remove
	tween.tween_interval(0.3)
	tween.tween_callback(queue_free)

extends Camera3D

# Camera settings
const CAMERA_OFFSET = Vector3(0, 4, 10)  # Behind and above player
const CAMERA_SMOOTHING = 6.0  # Optimized for performance
const LOOK_AHEAD_DISTANCE = 5.0  # How far ahead to look
const TILT_AMOUNT = 2.0  # Reduced from 5.0 to 2.0 for subtle professional tilt

# Screen shake
var shake_intensity = 0.0
var shake_duration = 0.0
const SHAKE_DECAY = 5.0  # How quickly shake fades
var noise = FastNoiseLite.new()
var noise_time = 0.0

# References
@onready var player: CharacterBody3D = null
var target_position = Vector3.ZERO
var target_rotation = Vector3.ZERO

func _ready() -> void:
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.hit_effect.connect(_on_player_hit)
	
	# Camera settings for better visuals
	fov = 70.0  # Field of view
	near = 0.1
	far = 200.0

func _on_player_hit() -> void:
	# Start screen shake - optimized for performance
	shake_intensity = 0.3  # Reduced from 0.5 for better performance
	shake_duration = 0.2   # Reduced from 0.3 for performance

func _process(delta: float) -> void:
	if player:
		update_camera_position(delta)
		update_camera_rotation(delta)
	
	# Update screen shake
	if shake_duration > 0:
		shake_duration -= delta
		shake_intensity = max(0, shake_intensity - SHAKE_DECAY * delta)
		
		# Apply perlin noise shake offset
		noise_time += delta * 50  # Speed of noise
		var shake_x = noise.get_noise_2d(noise_time, 0) * shake_intensity
		var shake_y = noise.get_noise_2d(noise_time, 100) * shake_intensity
		var shake_z = noise.get_noise_2d(noise_time, 200) * shake_intensity
		
		global_position += Vector3(shake_x, shake_y, shake_z)
	else:
		shake_intensity = 0.0

func update_camera_position(delta: float) -> void:
	# Calculate target position (behind and above player)
	var player_pos = player.global_position
	target_position = player_pos + CAMERA_OFFSET
	
	# Look ahead in the direction of movement
	target_position.z -= LOOK_AHEAD_DISTANCE
	
	# Smooth follow
	global_position = global_position.lerp(target_position, CAMERA_SMOOTHING * delta)

func update_camera_rotation(delta: float) -> void:
	# Look at the player - optimized for performance
	var look_at_point = player.global_position + Vector3(0, 1, 0)
	look_at(look_at_point, Vector3.UP)
	
	# Add subtle tilt based on lane position - optimized interpolation
	var lane_offset = player.global_position.x
	var tilt = -lane_offset * TILT_AMOUNT
	rotation_degrees.z = lerp(rotation_degrees.z, tilt, 2.0 * delta)  # Reduced from 3.0 for performance

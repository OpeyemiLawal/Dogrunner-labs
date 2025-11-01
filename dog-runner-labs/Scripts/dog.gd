extends CharacterBody3D

# Movement constants
const LANE_DISTANCE = 3.0  # Distance between lanes
const LANE_SWITCH_SPEED = 8.0  # Optimized for performance
var base_speed = 5.0  # Base forward speed (will increase with difficulty)
const MAX_SPEED = 15.0  # Maximum speed cap
const SPEED_INCREASE_INTERVAL = 30.0  # Increase speed every 5 seconds
const SPEED_INCREMENT = 1.0  # How much to increase speed each interval
var difficulty_timer = 0.0
const JUMP_VELOCITY = 15.0
const GRAVITY = 30.0
const SLIDE_DURATION = 0.8  # How long the slide lasts
# Double jump
const MAX_JUMPS = 2
var jumps_left = MAX_JUMPS
signal health_changed(new_health: int, max_health: int)
signal hit_effect  # Emitted when player takes damage for visual effects
var max_health = 100
var current_health = max_health
enum Lane { LEFT = -1, CENTER = 0, RIGHT = 1 }
var current_lane: Lane = Lane.CENTER
var target_lane: Lane = Lane.CENTER

# Magnet power-up
var magnet_active = false
var magnet_timer = 0.0
const MAGNET_DURATION = 40.0  # 40 seconds
signal magnet_activated
signal magnet_deactivated

# Movement state
var is_jumping = false
var is_sliding = false
var is_grounded = true
var slide_timer = 0.0

# Swipe detection
var swipe_start_position = Vector2.ZERO
var is_swiping = false
const SWIPE_THRESHOLD = 50.0  # Minimum distance for a swipe

# Camera settings
const CAMERA_OFFSET = Vector3(0, 3, 8)  # Camera position relative to dog
const CAMERA_SMOOTHING = 5.0  # How smoothly camera follows

# References
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Add to player group
	add_to_group("player")
	
	# Initialize position
	position.x = 0.0
	position.y = 0.0
	position.z = 0.0
	
	# Start with run animation
	if animation_player:
		animation_player.play("run")

func _process(delta: float) -> void:
	handle_input()
	update_movement(delta)
	update_slide_timer(delta)
	update_animations()
	increase_difficulty(delta)
	update_magnet_timer(delta)

func _physics_process(delta: float) -> void:
	apply_physics(delta)

# ============================================
# INPUT HANDLING
# ============================================

func handle_input() -> void:
	# Mouse/Touch input for swipe detection
	if Input.is_action_just_pressed("ui_touch"):
		swipe_start_position = get_viewport().get_mouse_position()
		is_swiping = true
	
	if Input.is_action_just_released("ui_touch") and is_swiping:
		var swipe_end_position = get_viewport().get_mouse_position()
		detect_swipe(swipe_start_position, swipe_end_position)
		is_swiping = false
	
	# Keyboard controls for testing (can remove for production)
	if Input.is_action_just_pressed("ui_left"):
		move_left()
	if Input.is_action_just_pressed("ui_right"):
		move_right()
	if Input.is_action_just_pressed("ui_up"):
		jump()
	if Input.is_action_just_pressed("ui_down"):
		slide()

func detect_swipe(start_pos: Vector2, end_pos: Vector2) -> void:
	var swipe_vector = end_pos - start_pos
	
	# Check if swipe is long enough
	if swipe_vector.length() < SWIPE_THRESHOLD:
		return
	
	# Determine swipe direction
	var angle = swipe_vector.angle()
	
	# Convert angle to degrees for easier reading
	var angle_deg = rad_to_deg(angle)
	
	# Swipe Up (jump)
	if angle_deg > -135 and angle_deg < -45:
		jump()
	# Swipe Down (slide)
	elif angle_deg > 45 and angle_deg < 135:
		slide()
	# Swipe Left
	elif abs(angle_deg) > 135:
		move_left()
	# Swipe Right
	elif abs(angle_deg) < 45:
		move_right()

# ============================================
# MOVEMENT ACTIONS
# ============================================

func move_left() -> void:
	if is_sliding:
		return
	
	if current_lane == Lane.CENTER:
		target_lane = Lane.LEFT
	elif current_lane == Lane.RIGHT:
		target_lane = Lane.CENTER

func move_right() -> void:
	if is_sliding:
		return
	
	if current_lane == Lane.CENTER:
		target_lane = Lane.RIGHT
	elif current_lane == Lane.LEFT:
		target_lane = Lane.CENTER

func jump() -> void:
	if jumps_left > 0 and not is_sliding:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		is_jumping = true
		is_grounded = false
		
		# Play jump animation
		if animation_player:
			animation_player.play("jump")
		
		print("Dog jumped! Jumps left: ", jumps_left)

func slide() -> void:
	if is_grounded and not is_sliding:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		
		# Play slide animation
		if animation_player:
			animation_player.play("walksent")
		
		print("Dog sliding!")

# ============================================
# MOVEMENT UPDATE
# ============================================

func update_movement(delta: float) -> void:
	# Smooth lane transition
	var target_x = target_lane * LANE_DISTANCE
	position.x = lerp(position.x, target_x, LANE_SWITCH_SPEED * delta)
	
	# Update current lane when close enough
	if abs(position.x - target_x) < 0.1:
		current_lane = target_lane
	
	# Constant forward movement
	position.z -= base_speed * delta

func apply_physics(delta: float) -> void:
	# Apply gravity
	if not is_grounded:
		velocity.y -= GRAVITY * delta
	
	# Apply vertical velocity
	position.y += velocity.y * delta
	
	# Ground detection (simple version - you'll want raycasting later)
	if position.y <= 0.0:
		position.y = 0.0
		velocity.y = 0.0
		is_grounded = true
		is_jumping = false
		jumps_left = MAX_JUMPS

func update_slide_timer(delta: float) -> void:
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
			# Return to run animation
			if animation_player and is_grounded:
				animation_player.play("run")
			print("Slide ended")

# ============================================
## & ANIMATION
# ============================================
func update_animations() -> void:
	if not animation_player:
		return
	
	# Return to run animation when landing
	if is_grounded and not is_sliding and not is_jumping:
		if animation_player.current_animation != "run":
			animation_player.play("run")

# ============================================
# UTILITY FUNCTIONS
# ============================================

func get_current_lane_position() -> float:
	return current_lane * LANE_DISTANCE

func reset_position() -> void:
	position = Vector3(0, 0, 0)
	velocity = Vector3.ZERO
	current_lane = Lane.CENTER
	target_lane = Lane.CENTER
	is_jumping = false
	is_sliding = false
	is_grounded = true
	base_speed = 5.0  # Reset to initial speed
	difficulty_timer = 0.0  # Reset difficulty timer
	jumps_left = MAX_JUMPS  # Reset jumps
	print("Player reset - difficulty reset")

# ============================================
# HEALTH SYSTEM
# ============================================

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	hit_effect.emit()  # Visual effect
	
	if current_health <= 0:
		die()
	else:
		print("Player took damage! Health: ", current_health)

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	print("Player healed! Health: ", current_health)

func is_alive() -> bool:
	return current_health > 0

func die() -> void:
	print("Player died! Reloading scene...")
	get_tree().reload_current_scene()

func increase_difficulty(delta: float) -> void:
	difficulty_timer += delta
	
	# Increase speed every 5 seconds
	if difficulty_timer >= SPEED_INCREASE_INTERVAL:
		difficulty_timer = 0.0
		
		# Increase speed but cap at MAX_SPEED
		if base_speed < MAX_SPEED:
			base_speed += SPEED_INCREMENT
			print("Difficulty increased! Speed now: ", base_speed)

# ============================================
# MAGNET POWER-UP SYSTEM
# ============================================

func update_magnet_timer(delta: float) -> void:
	if magnet_active:
		magnet_timer -= delta
		if magnet_timer <= 0.0:
			deactivate_magnet()

func activate_magnet() -> void:
	if not magnet_active:
		magnet_active = true
		magnet_timer = MAGNET_DURATION
		magnet_activated.emit()
		print("Magnet activated! Duration: ", MAGNET_DURATION, " seconds")

func deactivate_magnet() -> void:
	magnet_active = false
	magnet_timer = 0.0
	magnet_deactivated.emit()
	print("Magnet deactivated!")

func _on_magnet_collected() -> void:
	activate_magnet()

func is_magnet_active() -> bool:
	return magnet_active

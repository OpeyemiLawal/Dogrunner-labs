extends Node3D

# ============================================
# PROFESSIONAL PROCEDURAL LEVEL GENERATOR
# For endless runner with 3-lane system
# ============================================

# Configuration
const TILE_SIZE = 4.0  # Size of each floor tile
const TILES_AHEAD = 40  # Increased from 20 for better visibility
const TILES_BEHIND = 2  # Optimized for performance
const LANE_WIDTH = 3.0  # Distance between lanes
const WALL_HEIGHT = 4.0  # Height of side walls

# Spawn probabilities (0.0 to 1.0) - Exported for easy adjustment
@export_range(0.0, 1.0) var wall_decoration_chance: float = 0.15  # Reduced from 0.2 for performance
@export_range(0.0, 1.0) var pillar_chance: float = 0.12  # Reduced from 0.2 for performance
@export_range(0.0, 1.0) var floor_detail_chance: float = 0.08  # Reduced from 0.1 for performance
@export_range(0.0, 1.0) var obstacle_chance: float = 0.4  # 40% chance for obstacles from start
@export_range(0.0, 1.0) var collectible_chance: float = 0.3  # 30% chance per lane
@export_range(0.0, 1.0) var collectible_cluster_chance: float = 0.2  # 20% chance for cluster instead of single
@export_range(0.0, 1.0) var magnet_chance: float = 0.04  # 4% chance to spawn magnet instead of coins

# Asset paths - Floor tiles
var floor_tiles = [
	"res://Assets/Enviroment/gltf/floor_tile_large.gltf",
	"res://Assets/Enviroment/gltf/floor_tile_small.gltf",
	"res://Assets/Enviroment/gltf/floor_tile_small_decorated.gltf",
]

# Asset paths - Obstacles
var obstacle_models = [
	"res://Scene/obstacle/obstacle_1.tscn",  # Custom obstacle with damage
	"res://Scene/obstacle/obstacle_2.tscn",  # Shooting laser obstacle
	"res://Scene/obstacle/obstacle_3.tscn",  # Falling tile obstacle
	"res://Scene/obstacle/obstacle_4.tscn",  # Full-width 3-lane obstacle
]

# Asset paths - Wall decorations (AAA quality, no blue)
var wall_decorations = [
	"res://Assets/Enviroment/gltf/torch_lit.gltf",  # Primary: Lit torches
	"res://Assets/Enviroment/gltf/sword_shield.gltf",  # Secondary: Sword & shield
	"res://Assets/Enviroment/gltf/sword_shield_gold.gltf",  # Accent: Gold variant
]

# Asset paths - Architectural elements (clean, professional)
var pillar_models = [
	"res://Assets/Enviroment/gltf/pillar.gltf",
	"res://Assets/Enviroment/gltf/pillar_decorated.gltf",
	"res://Assets/Enviroment/gltf/column.gltf",
]

# Asset paths - Floor decorations (AAA quality ground details)
var floor_decorations = [
	"res://Assets/Enviroment/gltf/candle_lit.gltf",
	"res://Assets/Enviroment/gltf/candle_triple.gltf",
]

# Asset paths - Side walls
var wall_models = [
	"res://Assets/Enviroment/gltf/wall.gltf",
	"res://Assets/Enviroment/gltf/wall_half.gltf",
]

# Asset paths - Collectibles ($XYZ tokens)
var collectible_model = "res://Scene/obstacle/coin.tscn"
var magnet_model = "res://Scene/collectaible/magnet.tscn"

var decoration_patterns = ["torch_pair", "shield_pair", "torch_pair_center", "shield_pair_gold"]
var _decoration_index = 0
var _resource_cache: Dictionary = {}
var obstacle_collision_shape := BoxShape3D.new()
var collectible_collision_shape := SphereShape3D.new()
var _last_torch_spawn_z := -9999.0
var _last_shield_spawn_z := -9999.0

# Level state
var current_tile_z = 100.0  # Adjusted for 50 tiles ahead
var active_tiles = []  # Array of spawned tile containers
var player_ref = null  # Reference to player
var current_difficulty: float = 0.0  # Current difficulty level (0.0 to 1.0)

# ============================================
# INITIALIZATION
# ============================================

func _ready() -> void:
	# Wait a frame for player to be ready
	await get_tree().process_frame
	
	# Find player reference
	player_ref = get_tree().get_first_node_in_group("player")
	
	if not player_ref:
		push_warning("LevelSpawner: No player found in 'player' group!")
	
	preload_resources()
	obstacle_collision_shape.size = Vector3(1.5, 2.0, 1.5)  # Obstacles enabled
	collectible_collision_shape.radius = 0.5  # Collectibles disabled
	
	print("Level spawner initialized with ", active_tiles.size(), " tiles")

func _process(_delta: float) -> void:
	if not player_ref:
		return
	
	# Check if we need to spawn new tiles
	var player_z = player_ref.global_position.z
	var spawn_threshold = current_tile_z + (TILE_SIZE * 20)  # Adjusted for 40 tiles ahead
	
	# Player moves in negative Z, so check if player has passed the threshold
	if player_z < spawn_threshold:
		spawn_tile_segment()
	
	# Clean up old tiles behind player
	cleanup_old_tiles(player_z)

func preload_resources() -> void:
	var resources: Array = []
	resources.append_array(floor_tiles)
	resources.append_array(obstacle_models)  # Obstacles enabled
	resources.append_array(wall_decorations)
	resources.append_array(pillar_models)
	resources.append_array(floor_decorations)
	resources.append_array(wall_models)
	resources.append(collectible_model)  # Collectibles enabled
	resources.append(magnet_model)  # Magnet power-up
	for path in resources:
		if path is String and not _resource_cache.has(path):
			var resource = ResourceLoader.load(path)
			if resource:
				_resource_cache[path] = resource

# ============================================
# TILE SPAWNING
# ============================================

func spawn_tile_segment() -> void:
	"""Spawns a complete tile segment with floor, walls, and subtle decorations"""
	
	# Create container for this tile segment
	var tile_container = Node3D.new()
	tile_container.name = "TileSegment_" + str(current_tile_z)
	tile_container.position = Vector3(0, 0, current_tile_z)
	add_child(tile_container)
	
	# Add floor
	add_floor_tile(tile_container)
	
	# Add side walls
	add_side_walls(tile_container)
	
	# AAA-Quality decoration spawning with strategic placement
	var decoration_roll = randf()
	
	if decoration_roll < wall_decoration_chance:
		# Wall decorations (torches, shields) - Professional placement
		add_decorations(tile_container)
	elif decoration_roll < (wall_decoration_chance + pillar_chance):
		# Architectural pillars - Clean structural elements
		add_pillars(tile_container)
	
	# Floor details (independent layer) - Subtle ground atmosphere
	if randf() < floor_detail_chance:
		add_floor_decorations(tile_container)
	
	# Obstacles (ensure gameplay challenge) - Scaled by difficulty
	var obstacle_spawn_chance = obstacle_chance + (current_difficulty * 0.5)  # Increases from 40% to 90% max
	if randf() < obstacle_spawn_chance:
		add_obstacles(tile_container)
	
	# Collectibles ($XYZ tokens) - Random placement in lanes
	if randf() < collectible_chance:
		add_collectibles(tile_container)
	
	# Track this tile
	active_tiles.append({
		"container": tile_container,
		"z_position": current_tile_z
	})
	
	# Move to next tile position
	current_tile_z -= TILE_SIZE

# ============================================
# FLOOR GENERATION
# ============================================

func add_floor_tile(parent: Node3D) -> void:
	"""Adds floor tiles covering the 3-lane width"""
	
	# Use consistent large floor tile for seamless connection
	var floor_path = "res://Assets/Enviroment/gltf/floor_tile_large.gltf"
	var floor = load_model(floor_path)
	
	if floor:
		floor.name = "Floor"
		floor.position = Vector3(0, 0, 0)
		floor.scale = Vector3(3.5, 1.0, 1.2)  # Slightly narrower (3.5 instead of 4.0)
		parent.add_child(floor)

# ============================================
# WALL GENERATION
# ============================================

func add_side_walls(parent: Node3D) -> void:
	"""Adds walls on both sides of the track"""
	
	# Use consistent wall model (not random) for seamless connection
	var wall_path = "res://Assets/Enviroment/gltf/wall.gltf"
	
	# Left wall - adjusted for narrower floor
	var left_wall = load_model(wall_path)
	if left_wall:
		left_wall.name = "WallLeft"
		left_wall.position = Vector3(-LANE_WIDTH * 1.75, 0, 0)  # Adjusted to 1.75 to match floor
		left_wall.rotation_degrees = Vector3(0, 90, 0)
		left_wall.scale = Vector3(1.2, 2.5, 1.0)  # Stretch along tile length (X after rotation), taller (Y)
		parent.add_child(left_wall)
	
	# Right wall - adjusted for narrower floor
	var right_wall = load_model(wall_path)
	if right_wall:
		right_wall.name = "WallRight"
		right_wall.position = Vector3(LANE_WIDTH * 1.75, 0, 0)  # Adjusted to 1.75 to match floor
		right_wall.rotation_degrees = Vector3(0, -90, 0)
		right_wall.scale = Vector3(1.2, 2.5, 1.0)  # Stretch along tile length (X after rotation), taller (Y)
		parent.add_child(right_wall)

# ============================================
# OBSTACLE GENERATION
# ============================================

func add_obstacles(parent: Node3D) -> void:
	"""Adds obstacles - either individual lane obstacles or full-width 3-lane obstacles"""
	
	if obstacle_models.size() == 0:
		return  # No obstacles to spawn
	
	# Chance to spawn full-width 3-lane obstacle (scales with difficulty)
	var three_lane_chance = 0.2 + (current_difficulty * 0.3)  # 20% to 50% chance
	
	if randf() < three_lane_chance:
		# Spawn full-width 3-lane obstacle
		add_three_lane_obstacle(parent)
	else:
		# Spawn individual lane obstacles (old logic)
		add_individual_lane_obstacles(parent)

func add_three_lane_obstacle(parent: Node3D) -> void:
	"""Spawns a single obstacle that blocks all 3 lanes"""
	
	# Use obstacle_4 (the full-width obstacle) or fall back to obstacle_1
	var obstacle_path = "res://Scene/obstacle/obstacle_4.tscn"
	if not ResourceLoader.exists(obstacle_path):
		obstacle_path = "res://Scene/obstacle/obstacle_1.tscn"  # Fallback
	
	var obstacle = load_model(obstacle_path)
	
	if obstacle:
		obstacle.name = "Obstacle_3Lane"
		obstacle.position = Vector3(0, 0, 0)  # Center position
		# Scale to cover all 3 lanes (about 6 units wide total)
		obstacle.scale = Vector3(3.0, 1.0, 1.0)  # Scale X to cover all lanes
		
		# Check obstacle type and add appropriate collision
		if obstacle is StaticBody3D:
			obstacle.add_to_group("obstacles")
			parent.add_child(obstacle)
		else:
			# Create StaticBody3D wrapper with large collision box for 3 lanes
			var static_body = StaticBody3D.new()
			static_body.name = "Obstacle_3Lane"
			static_body.position = Vector3(0, 0, 0)
			
			# Add the visual obstacle
			static_body.add_child(obstacle)
			
			# Add large collision shape covering all 3 lanes
			var collision = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(LANE_WIDTH * 3, 2.0, 2.0)  # Cover all 3 lanes width
			collision.shape = box_shape
			collision.position = Vector3(0, 1.0, 0)
			static_body.add_child(collision)
			
			static_body.add_to_group("obstacles")
			parent.add_child(static_body)

func add_individual_lane_obstacles(parent: Node3D) -> void:
	"""Adds obstacles to random lanes (ensures at least one lane is clear) - old logic"""
	
	var lanes = [-1, 0, 1]  # Left, Center, Right
	var blocked_lanes = []
	
	# Scale number of obstacles based on difficulty (0-1 at low difficulty, up to 0-2 at max difficulty)
	var max_obstacles = 1 + int(current_difficulty * 1.0)  # Increases from 1 to 2 max obstacles per tile
	var num_obstacles = randi() % (max_obstacles + 1)  # 0 to max_obstacles
	
	for i in range(num_obstacles):
		if lanes.size() == 1:
			break  # Keep at least one lane open
		
		var lane_index = randi() % lanes.size()
		var lane = lanes[lane_index]
		lanes.remove_at(lane_index)
		
		# Spawn obstacle in this lane (exclude obstacle_4 from individual lane spawning)
		var available_obstacles = obstacle_models.duplicate()
		available_obstacles.erase("res://Scene/obstacle/obstacle_4.tscn")  # Remove 3-lane obstacle
		
		var obstacle_path = available_obstacles[randi() % available_obstacles.size()]
		var obstacle = load_model(obstacle_path)
		
		if obstacle:
			obstacle.name = "Obstacle_Lane" + str(lane)
			obstacle.position = Vector3(lane * LANE_WIDTH, 0, 0)
			
			# Check obstacle type - optimized for performance
			if obstacle is StaticBody3D:
				# Already has collision, just add to group and parent
				obstacle.add_to_group("obstacles")
				parent.add_child(obstacle)
			else:
				# Wrap GLTF model in StaticBody3D - optimized collision shape
				var static_body = StaticBody3D.new()
				static_body.add_child(obstacle)
				
				# Use simpler collision shape for better performance
				var collision = CollisionShape3D.new()
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3(1.2, 1.8, 1.2)  # Slightly smaller for performance
				collision.shape = box_shape
				collision.position = Vector3(0, 0.9, 0)  # Lower position
				static_body.add_child(collision)
				
				static_body.add_to_group("obstacles")
				parent.add_child(static_body)

func add_decorations(parent: Node3D) -> void:
	"""AAA-Quality wall decorations with professional placement"""
	
	var deco_path = wall_decorations[randi() % wall_decorations.size()]
	var is_torch = "torch" in deco_path
	var is_shield = "sword_shield" in deco_path
	
	if is_torch:
		# Add torches on both sides for symmetry (professional look)
		var torch_path = "res://Assets/Enviroment/gltf/torch_lit.gltf"
		
		# Left torch with AAA-quality placement
		var torch_left = load_model(torch_path)
		if torch_left:
			torch_left.name = "TorchLeft"
			torch_left.position = Vector3(-LANE_WIDTH * 1.7, 1.8, 0)  # Professional wall mount height
			torch_left.rotation_degrees = Vector3(0, 90, 0)
			torch_left.scale = Vector3(1.3, 1.3, 1.3)  # Balanced scale
			
			# Add OmniLight3D for torch glow (highly optimized for performance)
			var light_left = OmniLight3D.new()
			light_left.name = "TorchLight"
			light_left.light_color = Color(1.0, 0.6, 0.3)  # Warm orange fire color
			light_left.light_energy = 1.0  # Reduced from 1.5 for performance
			light_left.omni_range = 4.0  # Reduced from 5.0 for performance
			light_left.omni_attenuation = 2.0  # Falloff
			light_left.shadow_enabled = false  # Disabled for performance
			light_left.position = Vector3(0, 0.8, 0)  # Adjusted position
			torch_left.add_child(light_left)
			
			parent.add_child(torch_left)
		
		# Right torch with AAA-quality placement
		var torch_right = load_model(torch_path)
		if torch_right:
			torch_right.name = "TorchRight"
			torch_right.position = Vector3(LANE_WIDTH * 1.7, 1.8, 0)  # Professional wall mount height
			torch_right.rotation_degrees = Vector3(0, -90, 0)
			torch_right.scale = Vector3(1.3, 1.3, 1.3)  # Balanced scale
			
			# Add OmniLight3D for torch glow (highly optimized for performance)
			var light_right = OmniLight3D.new()
			light_right.name = "TorchLight"
			light_right.light_color = Color(1.0, 0.6, 0.3)  # Warm orange fire color
			light_right.light_energy = 1.0  # Reduced from 1.5 for performance
			light_right.omni_range = 4.0  # Reduced from 5.0 for performance
			light_right.omni_attenuation = 2.0  # Falloff
			light_right.shadow_enabled = false  # Disabled for performance
			light_right.position = Vector3(0, 0.8, 0)  # Adjusted position
			torch_right.add_child(light_right)
			
			parent.add_child(torch_right)
	
	elif is_shield:
		# AAA-Quality sword & shield placement (heraldic display)
		var shield_left = load_model(deco_path)
		if shield_left:
			shield_left.name = "ShieldLeft"
			shield_left.position = Vector3(-LANE_WIDTH * 1.72, 2.4, 0)  # Premium heraldic height
			shield_left.rotation_degrees = Vector3(0, 90, 0)
			shield_left.scale = Vector3(1.1, 1.1, 1.1)  # Slightly larger for prominence
			parent.add_child(shield_left)
		
		var shield_right = load_model(deco_path)
		if shield_right:
			shield_right.name = "ShieldRight"
			shield_right.position = Vector3(LANE_WIDTH * 1.72, 2.4, 0)  # Premium heraldic height
			shield_right.rotation_degrees = Vector3(0, -90, 0)
			shield_right.scale = Vector3(1.1, 1.1, 1.1)  # Slightly larger for prominence
			parent.add_child(shield_right)
	
	# No else - only torches and shields for clean AAA design

# ============================================
# ARCHITECTURAL PILLAR GENERATION
# ============================================

func add_pillars(parent: Node3D) -> void:
	"""AAA-Quality architectural pillars with professional placement"""
	
	var pillar_path = pillar_models[randi() % pillar_models.size()]
	
	# Professional pillar placement for grand corridor effect
	var pillar_left = load_model(pillar_path)
	if pillar_left:
		pillar_left.name = "PillarLeft"
		pillar_left.position = Vector3(-LANE_WIDTH * 1.7, 0, 0)  # Precise wall alignment
		pillar_left.rotation_degrees = Vector3(0, 0, 0)
		pillar_left.scale = Vector3(1.0, 2.0, 1.0)  # AAA proportions - taller, more imposing
		parent.add_child(pillar_left)
	
	var pillar_right = load_model(pillar_path)
	if pillar_right:
		pillar_right.name = "PillarRight"
		pillar_right.position = Vector3(LANE_WIDTH * 1.7, 0, 0)  # Precise wall alignment
		pillar_right.rotation_degrees = Vector3(0, 0, 0)
		pillar_right.scale = Vector3(1.0, 2.0, 1.0)  # AAA proportions - taller, more imposing
		parent.add_child(pillar_right)

# ============================================
# FLOOR DECORATION GENERATION
# ============================================

func add_floor_decorations(parent: Node3D) -> void:
	"""AAA-Quality floor decorations with strategic placement"""
	
	var deco_path = floor_decorations[randi() % floor_decorations.size()]
	
	# Strategic corner placement for professional look
	var side = -1 if randf() > 0.5 else 1
	
	var floor_deco = load_model(deco_path)
	if floor_deco:
		floor_deco.name = "FloorDecoration"
		floor_deco.position = Vector3(side * LANE_WIDTH * 1.5, 0.05, 0)  # Corner placement
		floor_deco.rotation_degrees = Vector3(0, randf() * 360, 0)  # Natural variation
		floor_deco.scale = Vector3(0.9, 0.9, 0.9)  # Subtle but visible
		parent.add_child(floor_deco)
		
		# Add small light to candles if it's a candle - optimized for performance
		if "candle" in deco_path:
			var candle_light = OmniLight3D.new()
			candle_light.name = "CandleLight"
			candle_light.light_color = Color(1.0, 0.7, 0.4)  # Warm candle glow
			candle_light.light_energy = 0.6  # Reduced from 0.8 for performance
			candle_light.omni_range = 2.0  # Reduced from 2.5 for performance
			candle_light.shadow_enabled = false
			candle_light.position = Vector3(0, 0.25, 0)  # Lower position
			floor_deco.add_child(candle_light)

# ============================================
# COLLECTIBLE GENERATION
# ============================================

func add_collectibles(parent: Node3D) -> void:
	"""Adds collectible $XYZ tokens or magnet power-ups in lanes"""
	
	var lanes = [-1, 0, 1]
	
	# Decide if cluster or single collectible/magnet
	if randf() < collectible_cluster_chance:
		# Spawn cluster in one lane
		var lane = lanes[randi() % lanes.size()]
		spawn_collectible_cluster(parent, lane)
	else:
		# Spawn single collectibles or magnet in random lanes
		var num_items = randi() % 2 + 1  # 1-2 items
		
		for i in range(num_items):
			if lanes.size() == 0:
				break
			
			var lane_index = randi() % lanes.size()
			var lane = lanes[lane_index]
			lanes.remove_at(lane_index)
			
			# 4% chance to spawn magnet instead of coins
			if randf() < magnet_chance:
				spawn_magnet(parent, lane)
			else:
				spawn_single_collectible(parent, lane, 0)

func spawn_single_collectible(parent: Node3D, lane: int, z_offset: float) -> void:
	"""Spawns a single collectible $XYZ token"""
	
	var token = load_model(collectible_model)
	
	if token:
		token.name = "Token_Lane" + str(lane)
		token.position = Vector3(lane * LANE_WIDTH, 1.0, z_offset)
		token.rotation_degrees = Vector3(0, 0, 0)
		
		# Check if the loaded token is already an Area3D (like coin.tscn)
		if token is Area3D:
			# Already has collision and is in collectibles group, just add to parent
			parent.add_child(token)
		else:
			# Wrap GLTF model in Area3D for collection detection
			var area = Area3D.new()
			var collision = CollisionShape3D.new()
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = 0.5
			collision.shape = sphere_shape
			
			area.add_child(token)
			area.add_child(collision)
			area.add_to_group("collectibles")
			area.collision_layer = 4  # Collectible layer
			area.collision_mask = 1   # Player layer
			
			parent.add_child(area)
			
			# Add rotation animation
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(token, "rotation_degrees:y", 360, 2.0).from(0)

func spawn_collectible_cluster(parent: Node3D, lane: int) -> void:
	"""Spawns a cluster of $XYZ tokens in a line"""
	
	var cluster_size = randi() % 3 + 3  # 3-5 tokens
	var spacing = 0.8
	
	for i in range(cluster_size):
		var z_offset = i * spacing - (cluster_size * spacing / 2.0)
		spawn_single_collectible(parent, lane, z_offset)

func spawn_magnet(parent: Node3D, lane: int) -> void:
	"""Spawns a magnet power-up"""
	
	var magnet = load_model(magnet_model)
	
	if magnet:
		magnet.name = "Magnet_Lane" + str(lane)
		magnet.position = Vector3(lane * LANE_WIDTH, 1.0, 0)
		magnet.rotation_degrees = Vector3(0, 0, 0)
		
		# Check if the loaded magnet is already an Area3D
		if magnet is Area3D:
			# Connect the magnet collected signal to the player
			if player_ref:
				magnet.magnet_collected.connect(player_ref._on_magnet_collected)
			# Already has collision and is in collectibles group
			parent.add_child(magnet)
		else:
			# Wrap in Area3D if needed
			var area = Area3D.new()
			var collision = CollisionShape3D.new()
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = 0.5
			collision.shape = sphere_shape
			
			area.add_child(magnet)
			area.add_child(collision)
			area.add_to_group("collectibles")
			area.collision_layer = 4  # Collectible layer
			area.collision_mask = 1   # Player layer
			
			# Connect the magnet collected signal to the player
			if player_ref and magnet.has_signal("magnet_collected"):
				magnet.magnet_collected.connect(player_ref._on_magnet_collected)
			
			parent.add_child(area)

# ============================================
# CLEANUP
# ============================================

func cleanup_old_tiles(player_z: float) -> void:
	"""Removes tiles that are too far behind the player"""
	
	var cleanup_threshold = player_z + (TILES_BEHIND * TILE_SIZE)
	var tiles_to_remove = []
	
	for tile_data in active_tiles:
		if tile_data.z_position > cleanup_threshold:
			tiles_to_remove.append(tile_data)
	
	# Remove old tiles
	for tile_data in tiles_to_remove:
		if is_instance_valid(tile_data.container):
			tile_data.container.queue_free()
		active_tiles.erase(tile_data)

# ============================================
# UTILITY FUNCTIONS
# ============================================

func load_model(path: String) -> Node3D:
	"""Loads a GLTF model and returns its root node - optimized for performance"""
	
	# Check cache first for better performance
	if _resource_cache.has(path):
		var cached_scene = _resource_cache[path]
		if cached_scene:
			return cached_scene.instantiate()
	
	# Load and cache if not found
	if not ResourceLoader.exists(path):
		push_warning("Model not found: " + path)
		return null
	
	var scene = ResourceLoader.load(path)
	if scene:
		_resource_cache[path] = scene  # Cache for future use
		return scene.instantiate()
	
	return null

# ============================================
# PUBLIC API
# ============================================

func set_difficulty(difficulty: float) -> void:
	"""Adjusts spawn rates based on difficulty (0.0 to 1.0)"""
	current_difficulty = clamp(difficulty, 0.0, 1.0)  # Clamp to valid range
	
	# Optional: Print current difficulty for debugging
	print("Difficulty set to: ", current_difficulty)

func reset_level() -> void:
	"""Clears all tiles and resets the spawner"""
	
	for tile_data in active_tiles:
		if is_instance_valid(tile_data.container):
			tile_data.container.queue_free()
	
	active_tiles.clear()
	current_tile_z = 0.0
	current_difficulty = 0.0  # Reset difficulty
	
	# Respawn initial tiles
	for i in range(TILES_AHEAD):
		spawn_tile_segment()

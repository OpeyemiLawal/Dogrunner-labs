extends Node3D

# Environment references
@onready var directional_light: DirectionalLight3D
@onready var environment: WorldEnvironment

func _ready() -> void:
	setup_lighting()
	setup_environment()
	setup_fog()

# ============================================
# LIGHTING SETUP
# ============================================

func setup_lighting() -> void:
	# Main directional light (sun/key light) - reduced brightness
	directional_light = DirectionalLight3D.new()
	directional_light.name = "MainLight"
	directional_light.light_energy = 0.8  # Reduced from 1.2 to 0.8
	directional_light.light_color = Color(0.95, 0.95, 1.0)  # Clean neutral white
	directional_light.rotation_degrees = Vector3(-40, 45, 0)
	
	# Enable shadows with optimized settings for performance
	directional_light.shadow_enabled = true
	directional_light.shadow_bias = 0.05
	directional_light.shadow_normal_bias = 1.0
	directional_light.shadow_blur = 1.5  # Softer shadows
	directional_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	directional_light.directional_shadow_max_distance = 50.0  # Limit shadow distance for performance
	
	add_child(directional_light)
	
	# Add fill light (softer, opposite side) - reduced
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_energy = 0.25  # Reduced from 0.4 to 0.25
	fill_light.light_color = Color(0.8, 0.85, 0.95)  # Subtle cool tint
	fill_light.rotation_degrees = Vector3(-30, -120, 0)
	fill_light.shadow_enabled = false
	add_child(fill_light)
	
	# Rim light (from behind for depth) - reduced
	var rim_light = DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.light_energy = 0.35  # Reduced from 0.6 to 0.35
	rim_light.light_color = Color(0.95, 0.95, 1.0)  # Clean white
	rim_light.rotation_degrees = Vector3(-20, 180, 0)
	rim_light.shadow_enabled = false
	add_child(rim_light)

# ============================================
# ENVIRONMENT SETUP
# ============================================

func setup_environment() -> void:
	environment = WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	
	var env = Environment.new()
	
	# Background - Skybox for professional look
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	
	# Professional dark sky settings
	sky_material.sky_top_color = Color(0.05, 0.08, 0.15)  # Very dark blue at top
	sky_material.sky_horizon_color = Color(0.15, 0.18, 0.25)  # Slightly lighter at horizon
	sky_material.ground_bottom_color = Color(0.02, 0.03, 0.05)  # Almost black ground
	sky_material.ground_horizon_color = Color(0.08, 0.10, 0.14)  # Dark ground horizon
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.1
	
	sky.sky_material = sky_material
	env.sky = sky
	
	# Ambient light - reduced for cleaner shadows
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.28, 0.32)  # Subtle cool ambient
	env.ambient_light_energy = 0.35  # Reduced from 0.5 to 0.35
	
	# Tone mapping for professional colors
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95  # Reduced from 1.1 to 0.95 for less brightness
	env.tonemap_white = 1.0
	
	# Glow/Bloom - subtle for clean look
	env.glow_enabled = true
	env.glow_intensity = 0.15  # Reduced from 0.3 to 0.15
	env.glow_strength = 0.6  # Reduced from 0.8 to 0.6
	env.glow_bloom = 0.05  # Reduced from 0.1 to 0.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	# SSAO for professional depth - optimized for performance
	env.ssao_enabled = true
	env.ssao_radius = 0.8  # Reduced from 1.2 for better performance
	env.ssao_intensity = 1.5  # Reduced from 2.0 for performance
	env.ssao_detail = 0.3  # Reduced from 0.5 for performance
	env.ssao_horizon = 0.06
	env.ssao_sharpness = 0.98
	
	# Adjust for clean, professional visuals
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.95  # Reduced from 1.05 to 0.95
	env.adjustment_contrast = 1.15  # Increased from 1.1 to 1.15 for cleaner look
	env.adjustment_saturation = 1.05  # Reduced from 1.15 to 1.05 for cleaner colors
	
	environment.environment = env
	add_child(environment)

# ============================================
# FOG SETUP
# ============================================

func setup_fog() -> void:
	if environment and environment.environment:
		var env = environment.environment
		
		# Volumetric fog - optimized for performance while maintaining atmosphere
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.01  # Further reduced from 0.015 for performance
		env.volumetric_fog_albedo = Color(0.4, 0.45, 0.55)  # Cleaner, less saturated fog
		env.volumetric_fog_emission_energy = 0.0
		env.volumetric_fog_gi_inject = 0.3  # Reduced from 0.4 for performance
		env.volumetric_fog_anisotropy = 0.2
		env.volumetric_fog_length = 40.0  # Reduced from 64.0 for performance
		env.volumetric_fog_detail_spread = 1.5  # Reduced from 2.0 for performance

extends CanvasLayer

@onready var health_label: Label = $Control/HealthLabel
@onready var xyz_label: Label = $Control/XYZLabel
@onready var damage_flash: ColorRect = $Control/DamageFlash
@onready var xyz_flash: ColorRect = $Control/XYZFlash
@onready var magnet_timer_bar: TextureProgressBar = $Control/MagnetTimerBar
@onready var magnet_icon: TextureRect = $Control/MagnetIcon
@onready var mesh_instance_2d: MeshInstance2D = $Control/MeshInstance2D

var xyz_collected: int = 0

func _ready() -> void:
	# Find the player node
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.hit_effect.connect(_on_hit_effect)
		player.magnet_activated.connect(_on_magnet_activated)
		player.magnet_deactivated.connect(_on_magnet_deactivated)
		# Initialize with current health
		_on_health_changed(player.current_health, player.max_health)
	
	# $XYZ tokens will connect themselves when spawned
	# Hide magnet bar and icon initially
	if magnet_timer_bar:
		magnet_timer_bar.visible = false
	if magnet_icon:
		magnet_icon.visible = false
	

func _on_health_changed(new_health: int, max_health: int) -> void:
	if health_label:
		health_label.text = "Health: " + str(new_health) + "/" + str(max_health)

func _on_xyz_collected() -> void:
	xyz_collected += 1
	if xyz_label:
		xyz_label.text = "$XYZ: " + str(xyz_collected)
	
	# Play $XYZ collection flash effect
	if xyz_flash:
		play_xyz_flash()

func play_xyz_flash() -> void:
	# Create a golden flash effect for $XYZ collection
	var tween = create_tween()
	tween.tween_property(xyz_flash, "color", Color(1.0, 0.9, 0.0, 0.3), 0.1)  # Gold flash
	tween.tween_property(xyz_flash, "color", Color(1.0, 0.9, 0.0, 0), 0.4)  # Fade out

func _on_hit_effect() -> void:
	if damage_flash:
		# Create a tween for flash effect
		var tween = create_tween()
		tween.tween_property(damage_flash, "color", Color(1, 0, 0, 0.4), 0.1)  # Red flash
		tween.tween_property(damage_flash, "color", Color(1, 0, 0, 0), 0.3)  # Fade out

func _on_magnet_activated() -> void:
	if magnet_timer_bar:
		magnet_timer_bar.visible = true
		magnet_timer_bar.value = 100  # Start at 100%
	if magnet_icon:
		magnet_icon.visible = true

func _on_magnet_deactivated() -> void:
	if magnet_timer_bar:
		magnet_timer_bar.visible = false
		magnet_timer_bar.value = 0
	if magnet_icon:
		magnet_icon.visible = false

func _process(delta: float) -> void:
	# Update magnet timer bar if magnet is active
	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_magnet_active() and magnet_timer_bar and magnet_timer_bar.visible:
		var remaining_time = player.magnet_timer
		var total_time = player.MAGNET_DURATION
		var percentage = (remaining_time / total_time) * 100
		magnet_timer_bar.value = percentage

extends Node3D

signal focus_lost
signal focus_gained
signal pose_recentered

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

@onready var right_hand: XRToolsHand = $XROrigin3D/RightHand/RightHand
const FLY = preload("res://Assignment/Scenes/fly.tscn")
@onready var open_xr_fb_scene_manager: OpenXRFbSceneManager = $XROrigin3D/OpenXRFbSceneManager

const FROG = preload("res://Assignment/Scenes/frog.tscn")
@export var maximum_refresh_rate : int = 90
@export var frogs = 3
@export var flies = 10
@onready var viewport : Viewport = get_viewport()
@onready var environment : Environment = $WorldEnvironment.environment

var xr_interface : OpenXRInterface
var xr_is_focussed = false
var toggle = true
# Called when the node enters the scene tree for the first time.
func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR instantiated successfully.")
		var vp : Viewport = get_viewport()

		# Enable XR on our viewport
		vp.use_xr = true

		# Make sure v-sync is off, v-sync is handled by OpenXR
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Enable VRS
		if RenderingServer.get_rendering_device():
			vp.vrs_mode = Viewport.VRS_XR
		elif int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
			push_warning("OpenXR: Recommend setting Foveation level to High in Project Settings")

		# Connect the OpenXR events
		xr_interface.session_begun.connect(_on_openxr_session_begun)
		xr_interface.session_visible.connect(_on_openxr_visible_state)
		xr_interface.session_focussed.connect(_on_openxr_focused_state)
		xr_interface.session_stopping.connect(_on_openxr_stopping)
		xr_interface.pose_recentered.connect(_on_openxr_pose_recentered)
		
				# Switch to Passthrough
		if switch_to_ar():
			print("Sucessfully Swapped To AR Blend Mode")
		else: print("Failed Swap TO AR Blend Mode")
	else:
		# We couldn't start OpenXR.
		print("OpenXR not instantiated!")
		#get_tree().quit()
	
	spawn_wildlife()

func spawn_wildlife():
	for i in range(frogs):
		var frog = FROG.instantiate()
		var x_rand = randf_range(-5, 5)
		var z_rand = randf_range(-5, 5)
		
		frog.global_position = Vector3(x_rand, 0, z_rand)
		add_child(frog)
	for i in range(flies):
		var fly = FLY.instantiate()
		var x_rand = randf_range(-5, 5)
		var z_rand = randf_range(-5, 5)
		
		fly.global_position = Vector3(x_rand, 1.5, z_rand)
		fly.visible = true
		add_child(fly)

# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	# Get the reported refresh rate
	var current_refresh_rate = xr_interface.get_display_refresh_rate()
	if current_refresh_rate > 0:
		print("OpenXR: Refresh rate reported as ", str(current_refresh_rate))
	else:
		print("OpenXR: No refresh rate given by XR runtime")

	# See if we have a better refresh rate available
	var new_rate = current_refresh_rate
	var available_rates : Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		print("OpenXR: Target does not support refresh rate extension")
	elif available_rates.size() == 1:
		# Only one available, so use it
		new_rate = available_rates[0]
	else:
		for rate in available_rates:
			if rate > new_rate and rate <= maximum_refresh_rate:
				new_rate = rate

	# Did we find a better rate?
	if current_refresh_rate != new_rate:
		print("OpenXR: Setting refresh rate to ", str(new_rate))
		xr_interface.set_display_refresh_rate(new_rate)
		current_refresh_rate = new_rate

	# Now match our physics rate
	Engine.physics_ticks_per_second = current_refresh_rate

# Handle OpenXR visible state
func _on_openxr_visible_state() -> void:
	# We always pass this state at startup,
	# but the second time we get this it means our player took off their headset
	if xr_is_focussed:
		print("OpenXR lost focus")

		xr_is_focussed = false

		# pause our game
		get_tree().paused = true

		emit_signal("focus_lost")

# Handle OpenXR focused state
func _on_openxr_focused_state() -> void:
	print("OpenXR gained focus")
	xr_is_focussed = true

	# unpause our game
	get_tree().paused = false

	emit_signal("focus_gained")

# Handle OpenXR stopping state
func _on_openxr_stopping() -> void:
	print("OpenXR is stopping")

func _on_openxr_pose_recentered() -> void:
	emit_signal("pose_recentered")
	
func switch_to_ar() -> bool:

	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
			viewport.transparent_bg = true
		elif XRInterface.XR_ENV_BLEND_MODE_ADDITIVE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ADDITIVE
			viewport.transparent_bg = false
	else:
		return false
	
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	return true

func _on_right_hand_button_pressed(name: String) -> void:
	if name == "trigger_click":
		var fly = FLY.instantiate()
		fly.position = right_hand.global_position - Vector3(0, 0, 5)
		add_child(fly)
		audio_stream_player_3d.play()
	if name == "ax_button":
		toggle = !toggle
		toggle_all_boid_gizmos(toggle)

func toggle_all_boid_gizmos(toggle: bool, node: Node = null):
	if node == null:
		node = get_tree().get_root()
	for child in node.get_children():
		if child is Boid:
			child.draw_gizmos_recursive(toggle)
		toggle_all_boid_gizmos(toggle, child) # recursive call

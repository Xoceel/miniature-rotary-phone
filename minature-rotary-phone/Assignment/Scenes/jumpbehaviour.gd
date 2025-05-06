class_name Jump extends SteeringBehavior
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

@export var jump_strength := 10
@export var jump_interval := 2.0  # seconds between jumps

var time_since_last_jump := 0.0

func _physics_process(delta: float) -> void:
	time_since_last_jump += get_physics_process_delta_time()
	get_parent().velocity.y += 600
	if time_since_last_jump >= jump_interval:
		animation_player.play("Jump")
		animation_player.animation_set_next("Jump", "Walking")
		jump_interval = randf_range(1.0, 3.0)
		time_since_last_jump = 0

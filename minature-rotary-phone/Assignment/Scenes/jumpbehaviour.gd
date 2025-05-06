class_name Jump extends SteeringBehavior

@export var jump_strength := 10
@export var jump_interval := 1.0  # seconds between jumps

var time_since_last_jump := 0.0

func calculate() -> Vector3:
	if !enabled:
		return Vector3.ZERO


	time_since_last_jump += get_physics_process_delta_time()

	if time_since_last_jump >= jump_interval:
		time_since_last_jump = 0.0
		return Vector3.UP * jump_strength
	else:
		return Vector3.ZERO

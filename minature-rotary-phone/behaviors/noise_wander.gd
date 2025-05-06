class_name NoiseWander extends SteeringBehavior

@export var frequency = 0.3
@export var radius = 10

@export var theta = 0
@export var amplitude = 5000
@export var distance = 5

enum Axis { Horizontal, Vertical}

@export var axis = Axis.Horizontal
var target:Vector3
var world_target:Vector3

# Instantiate
var noise:FastNoiseLite = FastNoiseLite.new()

func _ready():
	boid = get_parent()
	noise.seed = randi()
	noise.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	noise.set_frequency(0.01)
	noise.set_fractal_lacunarity(2)
	noise.set_fractal_gain(0.5)

func on_draw_gizmos():
	var cent = boid.global_transform * (Vector3.BACK * distance)
	DebugDraw3D.draw_sphere(cent, radius, Color.HOT_PINK)
	DebugDraw3D.draw_line(boid.global_transform.origin, cent, Color.HOT_PINK)
	DebugDraw3D.draw_line(cent, world_target, Color.HOT_PINK)
	DebugDraw3D.draw_position(Transform3D(Basis(), world_target), Color.HOT_PINK)
	
	
func calculate():		
	var n = noise.get_noise_1d(theta)
	var angle = deg_to_rad(n * amplitude)

	var delta = get_process_delta_time()

	if axis == Axis.Horizontal:
		target.x = sin(angle)
		target.z = cos(angle)
		target.y = 0
	else:
		target.y = sin(angle)
		target.z = cos(angle)
		target.x = 0
		
	target *= radius

	var local_target = target + (Vector3.BACK * distance)

	# Construct a flat forward-facing basis
	var forward = -boid.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var flat_basis = Basis()
	flat_basis.z = -forward
	flat_basis.x = forward.cross(Vector3.UP).normalized()
	flat_basis.y = Vector3.UP

	world_target = boid.global_transform.origin + (flat_basis * local_target)
	theta += frequency * delta * PI * 2.0

	return boid.seek_force(world_target)

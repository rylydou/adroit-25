class_name Math extends RefCounted


static func rotate_90deg_left(vec: Vector2) -> Vector2:
	return Vector2(-vec.y, vec.x)


static func rotate_90deg_right(vec: Vector2) -> Vector2:
	return Vector2(vec.y, -vec.x)


static func jump_gravity(height: float, duration: float) -> float:
	return 8.0 * (height / pow(duration, 2.0))


static func jump_velocity(height: float, gravity: float) -> float:
	return sqrt(2.0 * gravity * height)

static func jump_height(y_velocity: float, gravity: float) -> float:
	return (y_velocity ** 2.0) / (2.0 * gravity)


static func smooth(factor: float, delta: float) -> float:
	return 1 - exp(-delta * factor)


static func friction(speed: float, deceleration: float, smoothing: float, delta: float) -> float:
	speed = move_toward(speed, 0.0, deceleration * delta)
	speed = lerp(speed, 0.0, Math.smooth(smoothing, delta))
	return speed


static func line_on_grid(a: Vector2, b: Vector2) -> Array[Vector2i]:
	var points: Array[Vector2i] = [];
	var N := diagonal_distance(a, b)
	for step in range(0, N + 1):
		var t := 0.0 if N == 0 else (float(step) / N)
		points.append(Vector2i(a.lerp(b, t).round()))
	return points


static func diagonal_distance(a: Vector2, b: Vector2) -> float:
	var dx := b.x - a.x
	var dy := b.y - a.y
	return maxf(absf(dx), absf(dy))


static func rand_sign() -> float:
	return -1.0 if rand_bool() else +1.0


static func rand_bool(prob := 0.5) -> bool:
	return randf() < prob


## Returns default if curve is null, or else samples a random point from 0.0 to 1.0
static func rand_on_curve(curve: Curve, default := 0.0) -> float:
	if not curve: return default
	return curve.sample_baked(randf())


## Random value with variation
static func rand_var(base_value: float, plus_or_minus: float) -> float:
	return base_value + randf_range(-plus_or_minus, plus_or_minus)


static func rand_dir() -> Vector2:
	return Vector2.from_angle(randf() * TAU)

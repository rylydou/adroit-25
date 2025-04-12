class_name PlayerCharacter extends CharacterBody2D


signal died()


@export var allow_midair_flip = true

@export_group("Movement", "move_")
@export var move_speed := 4.0

@export_range(0, 60, 1, "or_greater", "suffix:ticks") var move_acc_ticks := 8.0
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var move_dec_ticks := 6.0
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var move_opp_ticks := 4.0

@export_range(0, 60, 1, "or_greater", "suffix:ticks") var move_acc_air_ticks := 16.0
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var move_dec_air_ticks := 12.0
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var move_opp_air_ticks := 8.0

@export_group("Gravity and Jump")
@export_range(0, 16, 1, "or_greater", "suffix:px") var jump_height_min := 1.0
@export_range(0, 16, 1, "or_greater", "suffix:px") var jump_height_max := 3.0
@export_range(0, 120, 1, "or_greater", "suffix:ticks") var jump_ticks := 30.0
@export_range(0, 120, 1, "or_greater", "suffix:ticks") var fall_ticks := 30.0
var fall_gravity := 0.0
var jump_gravity := 0.0
var jump_velocity_min := 0.0
var jump_velocity_max := 0.0
@export var step_time := 0.2
var step_timer := 0.0

## The maximum falling speed based on the max jump height
@export var max_fall_ratio := 2.0
var max_fall_speed := 0.0
var is_jumping := false

@export var bonk_bounce := 0.0

@export_group("Assists")
## The amount of time the player can still jump after leaving a platform, see "Looney Tunes"
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var coyote_time_ticks := 3.0
var coyote_timer := -1.0
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var jump_buffer_ticks := 3.0
var jump_buffer_timer := -1.0
@export_range(0, 60, 1, "or_greater", "suffix:ticks") var action_buffer_ticks := 3.0
var action_buffer_timer := -1.0
var fallthrough_ignore_timer := 0.0

## If the player hits their head on a corner then how far can they be nudged out of the way
@export_range(0, 16, 1, "or_greater", "suffix:px") var max_bonknudge_distance := 8.0
@export var allow_backward_bonknudge := false

@export_group("Climbing", "climb_")
@export var climb_speed_vertical := 4.0
@export var climb_speed_horizontal := 4.0
@export var climb_coyote_time := 3.0
var is_climbing := false

@export_group("Wallslide")
@export var wallslide_fall_speed := 1.0
@export var walljump_horizontal_speed := 4.0
@export var walljump_coyote_time := 3.0
var wallslide_norm := 0
var last_walljump_norm := 0

@export_group("Water", "water_")
@export_range(0, 16, 1, "or_greater", "suffix:px") var water_surface_jump_height := 24.0
var water_surface_jump_vel := 0.0
@export var water_ratio := 0.5
@export var water_gravity_ratio := 0.5
@export var water_max_fall_ratio := 0.5

@export_group("Extra", "extra_")
@export var extra_bounce := 0.0
@export var extra_ground_dec := 0.0
@export var extra_ground_smooth := 0.0
@export var extra_air_dec := 0.0
@export var extra_air_smooth := 0.0


@onready var climb_area: Area2D = %"Climb Area"
@onready var flip_node: Node2D = %"Flip"
@onready var sprite: Sprite2D = %"Sprite"
@onready var water_area: Area2D = %"Water Area"
@onready var punch_area: Area2D = %"Punch Area"

## Temporary
@onready var og_spawn_position := global_position


@onready var gamepad := Gamepad.create(-2)

var age := 0.0

var is_dead := false
var is_grounded := false
var in_water := false
var direction := 1.0
var jumped_from_ladder := false
var was_on_wall := false

var last_vel := Vector2.ZERO
var vel_move := 0.0
var vel_extra := 0.0


func _enter_tree() -> void:
	calculate_physics()


func calculate_physics() -> void:
	jump_gravity = Math.jump_gravity(jump_height_max, jump_ticks * 2 / Global.TPS)
	fall_gravity = Math.jump_gravity(jump_height_max, fall_ticks * 2 / Global.TPS)
	
	jump_velocity_min = Math.jump_velocity(jump_height_min, jump_gravity)
	jump_velocity_max = Math.jump_velocity(jump_height_max, jump_gravity)
	water_surface_jump_vel = Math.jump_velocity(water_surface_jump_height, jump_gravity)
	
	max_fall_speed = jump_velocity_max * max_fall_ratio
	
	Global.gravity = fall_gravity


func _physics_process(delta: float) -> void:
	if Global.debug_physics:
		queue_redraw()
	
	age += delta
	
	gamepad.poll(delta)
	
	if not is_dead:
		_process_physics(delta)


func _process_physics(delta: float) -> void:
	if test_move(
		transform.translated(Vector2.UP * 2.0).scaled_local(Vector2.ONE * 0.1),
		Vector2.UP, null, 0.0, true):
		die()
	
	jump_buffer_timer -= delta
	if gamepad.jump.pressed:
		jump_buffer_timer = jump_buffer_ticks / Global.TPS
	
	action_buffer_timer -= delta
	if gamepad.punch.pressed:
		action_buffer_timer = action_buffer_ticks / Global.TPS
	
	if wallslide_norm != 0 and coyote_timer > 0.0:
		direction = wallslide_norm
	elif (is_on_floor() or allow_midair_flip) and not is_zero_approx(gamepad.move.x):
		direction = sign(gamepad.move.x)
	
	if flip_node:
		flip_node.scale.x = direction
	
	var was_in_water := in_water
	in_water = water_area.get_overlapping_areas().size() > 0
	
	if was_in_water and not in_water:
		# Leaving water
		if is_jumping:
			velocity.y = minf(velocity.y, -water_surface_jump_vel)
	
	if is_climbing:
		process_state_climb(delta)
	else:
		process_state_platformer(delta)
	
	fallthrough_ignore_timer -= delta
	
	if gamepad.punch.pressed:
		var things := punch_area.get_overlapping_bodies()
		things.append(punch_area.get_overlapping_areas())
		
		for thing in things:
			# if thing.owner:
				# thing = thing.owner
			
			thing.propagate_call(&"receive_punch", [0])


func process_state_platformer(delta: float) -> void:
	if is_on_floor():
		is_jumping = false
		wallslide_norm = 0
		last_walljump_norm = 0
	
	if (
		climb_area.get_overlapping_areas().size() + climb_area.get_overlapping_bodies().size() > 0
		and gamepad.move.y < 0.0
		and velocity.y > -climb_speed_vertical
	):
		is_climbing = true
		is_jumping = false
		wallslide_norm = 0
		last_walljump_norm = 0
		return
	
	process_movement(delta)
	process_gravity(delta)
	process_wallslide(delta)
	process_jump(delta)
	
	move(delta)


func process_state_climb(delta: float) -> void:
	if climb_area.get_overlapping_bodies().size() == 0 or (is_on_floor() and gamepad.move.y > 0.0):
		is_climbing = false
		coyote_timer = climb_coyote_time / Global.TPS
		if gamepad.move.y < 0.0:
			apply_floor_snap()
			velocity.y = 0.0
		return
	
	vel_extra = 0.0
	velocity.y = gamepad.move.y * climb_speed_vertical
	vel_move = gamepad.move.x * climb_speed_horizontal
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = -1.0
		coyote_timer = -1.0
		velocity.y = -jump_velocity_max
		is_jumping = true
		is_climbing = false
		return
	
	move(delta)


func move(delta: float) -> void:
	var engine_vel = velocity.x - last_vel.x
	vel_extra += engine_vel
	velocity.x = vel_move + vel_extra + engine_vel
	
	last_vel.y = velocity.y
	
	if in_water:
		velocity *= water_ratio
	move_and_slide()
	if in_water:
		velocity /= water_ratio
	
	last_vel.x = velocity.x


func process_movement(delta: float) -> void:
	is_grounded = is_on_floor()
	var is_input_opposing = not is_zero_approx(vel_move) and sign(vel_move) != sign(gamepad.move.x)
	
	#print('is_input_opposing: ',is_input_opposing)
	
	var move_ticks := 0.0
	var extra_dec := 0.0
	var extra_smooth := 0.0
	if is_grounded: # grounded movement
		if gamepad.move.x == 0.0:
				move_ticks = -move_dec_ticks
		else:
			if is_input_opposing: # opposing movement
				move_ticks = move_opp_ticks
			else:
				move_ticks = move_acc_ticks
		extra_dec = extra_ground_dec
		extra_smooth = extra_ground_smooth
	else: # air movement
		if gamepad.move.x == 0.0:
			move_ticks = -move_dec_air_ticks
		else:
			if is_input_opposing: # opposing movement
				move_ticks = move_opp_air_ticks
			else:
				move_ticks = move_acc_air_ticks
		extra_dec = extra_air_dec
		extra_smooth = extra_air_smooth
	
	if move_ticks > 0.0:
		var speed: float = move_speed / (move_ticks / Global.TPS / delta)
		vel_move += gamepad.move.x * speed
	elif move_ticks < 0.0:
		vel_move = move_toward(vel_move, 0.0, move_speed / (-move_ticks / Global.TPS / delta))
		
		var max_speed := move_speed
		vel_move = clamp(vel_move, -max_speed, max_speed)
	
	vel_extra = move_toward(vel_extra, 0.0, extra_dec * delta)
	vel_extra = lerp(vel_extra, 0.0, Math.smooth(extra_smooth, delta))
	
	var hit_wall_on_left := is_on_wall() and test_move(transform, Vector2.LEFT)
	var hit_wall_on_right := is_on_wall() and test_move(transform, Vector2.RIGHT)
	
	if hit_wall_on_left:
		if vel_move < 0.0:
			vel_move = 0.0
		if vel_extra < 0.0:
			if gamepad.move.x < 0.0:
				vel_extra = 0.0
			else:
				vel_extra = -vel_extra * extra_bounce
	
	if hit_wall_on_right:
		if vel_move > 0.0:
			vel_move = 0.0
		if vel_extra > 0.0:
			if gamepad.move.x > 0.0:
				vel_extra = 0.0
			else:
				vel_extra = -vel_extra * extra_bounce


func process_gravity(delta: float) -> void:
	# Ceiling bonk
	if velocity.y < 0.0 and test_move(transform.translated(Vector2.UP), Vector2.UP * -velocity * delta):
		if not slide_on_ceiling and get_last_slide_collision() != null:
			if velocity.y < 0.0:
				velocity.y = -velocity.y * bonk_bounce
		if not try_bonknudge(max_bonknudge_distance * direction):
			if (
					not allow_backward_bonknudge or
					not try_bonknudge(-max_bonknudge_distance * direction)
			):
				if velocity.y < 0.0 and is_on_ceiling():
					velocity.y = -velocity.y * bonk_bounce
	
	# controllable jump height
	if is_jumping and not gamepad.jump.down:
		if velocity.y < -jump_velocity_min:
			velocity.y = -jump_velocity_min
	
	# Fallthrough semisolid platforms when jumping while holding down
	if is_on_floor():
		if fallthrough_ignore_timer > 0.0:
			position += -get_floor_normal()
			# fallthrough_ignore_timer = fallthrough_ignore_ticks / Global.TPS
			velocity.y = maxf(velocity.y, jump_velocity_min)
		else:
			velocity.y = minf(velocity.y, 0.0)
			coyote_timer = coyote_time_ticks / Global.TPS
	else:
		# Apply gravity in air
		var gravity = fall_gravity if velocity.y >= 0.0 else jump_gravity
		gravity *= Global.gravity_scale
		velocity.y += gravity * delta * (water_gravity_ratio if in_water else 1.0)
	
	# Cap fall speed
	velocity.y = minf(
			velocity.y,
			max_fall_speed * (water_max_fall_ratio if in_water else 1.0)
	)


func try_bonknudge(distance: float) -> bool:
	var x := 0.0
	while x != distance:
		if not test_move(transform.translated(Vector2(x, 0.0)), Vector2.UP):
			position.x += x
			return true
		x = move_toward(x, distance, 1.0)
	return false


func process_jump(delta: float) -> void:
	coyote_timer -= delta
	
	if fallthrough_ignore_timer > 0.0:
		if climb_area.get_overlapping_areas().size() + climb_area.get_overlapping_bodies().size() > 0:
			fallthrough_ignore_timer = 0.0
			is_climbing = true
	
	if jump_buffer_timer > 0.0:
		if gamepad.crouch.down and is_on_floor(): # if crouching then fall though
			#SoundBank.play("fallthrough", position)
			# position += -get_floor_normal()
			position.y += 2.0
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			var offset := abs(get_floor_normal().x)
			var fallthrough_ignore_ticks := 10.0
			fallthrough_ignore_timer = fallthrough_ignore_ticks / Global.TPS
			# velocity.y = maxf(velocity.y, jump_velocity_min)
			# velocity.y = 0.0
		elif coyote_timer > 0.0: # or else jump
			#SoundBank.play("jump", position)
			is_jumping = true
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			
			velocity.y = -jump_velocity_max
			if wallslide_norm != 0:
				last_walljump_norm = wallslide_norm
				vel_extra = wallslide_norm * walljump_horizontal_speed
				wallslide_norm = 0


func process_wallslide(delta: float) -> void:
	if (
			in_water
			or velocity.y <= 0.0
			or is_on_floor()
			or not test_move(
				transform.translated(Vector2.UP),
				Vector2(sign(gamepad.move.x),
				1.0)
			)
			or not is_on_wall()
	):
		was_on_wall = false
		return
	
	var input_norm := signi(gamepad.move.x)
	var wall_norm := get_wall_normal()
	if not (
			abs(wall_norm.x) >= 0.95
			and wall_norm.y <= 0.0
	):
		was_on_wall = false
		return
	
	was_on_wall = true
	wallslide_norm = signi(wall_norm.x)
	
	if (
			not was_on_wall
			or last_walljump_norm == wallslide_norm
			or wallslide_norm != -input_norm
		): return
	
	if velocity.y > wallslide_fall_speed:
		velocity.y = wallslide_fall_speed
	coyote_timer = walljump_coyote_time / Global.TPS


func grounded_refresh() -> void:
	was_on_wall = false
	wallslide_norm = 0
	last_walljump_norm = 0
	jumped_from_ladder = false
	fallthrough_ignore_timer = 0.0
	is_jumping = false


func airborne_refresh() -> void:
	grounded_refresh()
	coyote_timer = 0.0


func _draw() -> void:
	if not Global.debug_physics: return
	
	draw_line(Vector2.ZERO, Vector2(vel_move, 0.0), Color.WHITE, 2.0)
	draw_line(Vector2(0.0, -8.0), Vector2(vel_extra, -8.0), Color.RED, 2.0)
	draw_line(Vector2.ZERO, Vector2(0.0, velocity.y), Color.GREEN, 2.0)


# -------------------------------------------------------------------------------- #


func die() -> void:
	if is_dead: return
	is_dead = true
	
	SFX.event("death.player").at(self).play()
	
	sprite.frame = 0
	
	respawn()


func respawn() -> void:
	modulate.a = 0.5
	z_index += 1000
	scale = Vector2.ONE * 0.75
	
	var spawn_position := og_spawn_position
	
	var delta := spawn_position - position
	
	var duration := 1.0
	
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", TAU * 4.0, duration).from(0.0)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "position", spawn_position, duration)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	tween.kill()
	
	modulate.a = 1.0
	z_index -= 1000
	scale = Vector2.ONE
	vel_move = 0.0
	vel_extra = 0.0
	velocity = Vector2.ZERO
	last_vel = Vector2.ZERO
	is_dead = false

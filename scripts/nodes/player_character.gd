class_name PlayerCharacter extends CharacterBody2D


enum State {
	Grounded,
	Fall,
	Climb,
	Jump,
	DoubleJump,
	Dash,
	Pound,
	Grapple,
	Dead,
}



signal died()


var state := State.Grounded
var last_state := State.Grounded

@export var playerAnimParent: SubViewportContainer

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

@export_group("Double Jump", "double_jump_")
@export var double_jump_height := 32.0
@export var double_jump_move_speed := 0.0
@export var double_jump_extra_speed := 0.0
var double_jump_velocity := 0.0
var can_double_jump := true

@export_group("Dash", "dash_")
@export var dash_distance_curve: Curve
var dash_og_x := 0.0
var dash_timer := 0.0
var can_dash := true

@export_group("Pound", "pound_")
@export var pound_speed := 100.0
var olddirection
var can_pound := 0.0


@export_group("Grapple", "grapple_")
@export var grapple_speed_curve: Curve
@export var grapple_min_distance := 16.0
@export var grapple_max_distance := 8.0 * 30.0
@export var max_grapple_time := 10.0
var grappling_time := 0.0
var grapple_target_x := 0.0


@onready var climb_area: Area2D = %"Climb Area"
@onready var flip_node: Node2D = %"Flip"
@onready var water_area: Area2D = %"Water Area"
@onready var punch_area: Area2D = %"Punch Area"
@onready var interact_area: Area2D = %"Interact Area"
@onready var unsafe_area: Area2D = %"Unsafe Area"
@onready var collision_normal: CollisionShape2D = %"Normal Collision"
@onready var collision_dash: CollisionShape2D = %"Dash Collision"
@onready var grapple_ray_cast: RayCast2D = %"Grapple Raycast"
@onready var grapple_gfx: Node2D = %"Grapple GFX"
@onready var grapple_line: Line2D = %"Grapple Line"
@onready var talk_label: RichTextLabel = %"Talk"

@onready var respawn_point := global_position


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
	Global.player = self
	calculate_physics()


func _ready() -> void:
	for emotion in [
		&"fear",
		&"depression",
		&"anger",
		&"joy",
		&"love",
	]:
		DevTools.new_command("Give Emotion %s" % emotion)\
			.describe("Gives the specified emotion upgrade")\
			.exec(func():
			Global.emotions.erase(emotion) # ensure there are no duplicates
			Global.emotions.append(emotion)
			)
	
	grapple_gfx.hide()
	talk_label.hide()


func calculate_physics() -> void:
	jump_gravity = Math.jump_gravity(jump_height_max, jump_ticks * 2 / Global.TPS)
	fall_gravity = Math.jump_gravity(jump_height_max, fall_ticks * 2 / Global.TPS)
	
	jump_velocity_min = Math.jump_velocity(jump_height_min, jump_gravity)
	jump_velocity_max = Math.jump_velocity(jump_height_max, jump_gravity)
	double_jump_velocity = Math.jump_velocity(double_jump_height, jump_gravity)
	water_surface_jump_vel = Math.jump_velocity(water_surface_jump_height, jump_gravity)
	
	max_fall_speed = jump_velocity_max * max_fall_ratio
	
	Global.gravity = fall_gravity


func _physics_process(delta: float) -> void:
	if Global.debug_physics:
		queue_redraw()
	
	age += delta
	gamepad.poll(delta)
	
	playerAnimParent.playerAnime.tree["parameters/conditions/idle"] = is_grounded and abs(vel_move) <= 0.1
	playerAnimParent.playerAnime.tree["parameters/conditions/run"] = is_grounded and abs(vel_move) > 0
	playerAnimParent.playerAnime.tree["parameters/conditions/jump"] = state == State.Jump
	playerAnimParent.playerAnime.tree["parameters/conditions/hitground"] = is_grounded
	playerAnimParent.playerAnime.tree["parameters/conditions/idle"] = abs(vel_move) == 0
	
	
	if not is_dead:
		_process_physics(delta)
		


func _process_physics(delta: float) -> void:
	last_state = state
	
	if Input.is_action_just_pressed(&"teleport"):
		position = get_global_mouse_position()
	
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
	var fliponce = false
	if wallslide_norm != 0 and coyote_timer > 0.0:
		direction = wallslide_norm
	elif (is_on_floor() or allow_midair_flip) and not dash_timer > 0.0 and not is_zero_approx(gamepad.move.x):
		#if sign(gamepad.move.x) != direction:
			#playerAnimParent.flip =sign(gamepad.move.x)
		direction = sign(gamepad.move.x)
		playerAnimParent.flip = direction
		#playerAnimParent.flipplayer.play("flip")
		
		
	if flip_node:
		flip_node.scale.x = direction
	
	var was_in_water := in_water
	in_water = water_area.get_overlapping_areas().size() > 0
	
	if was_in_water and not in_water:
		# Leaving water
		if is_jumping:
			velocity.y = minf(velocity.y, -water_surface_jump_vel)
	
	if dash_timer > 0.0:
		process_state_dash(delta)
	elif is_climbing:
		process_state_climb(delta)
	else:
		process_state_platformer(delta)
	
	fallthrough_ignore_timer -= delta
	
	if gamepad.punch.pressed and Global.emotions.has(&"anger") and is_grounded:
		var things := punch_area.get_overlapping_bodies()
		things.append_array(punch_area.get_overlapping_areas())
		
		for thing in things:
			thing.propagate_call(&"receive_punch", [0])
	
	if can_dash and gamepad.dash.pressed and Global.emotions.has(&"fear"):
		can_dash = false
		dash_timer = dash_distance_curve.max_domain / Global.TPS
		dash_og_x = position.x


func process_state_platformer(delta: float) -> void:
	if is_on_floor() and state != State.Grapple and state != State.Dash:
		if state == State.Pound:
			Global.camera.pound_shake()
		
		state = State.Grounded
		is_jumping = false
		can_double_jump = true
		can_dash = true
		wallslide_norm = 0
		last_walljump_norm = 0
	
	if (is_grounded or state == State.Dash) and unsafe_area.get_overlapping_areas().size() > 0:
		respawn_point = global_position
	
	if (
		climb_area.get_overlapping_areas().size() + climb_area.get_overlapping_bodies().size() > 0
		and gamepad.move.y < 0.0
		and velocity.y > -climb_speed_vertical
	):
		can_dash = true
		state = State.Climb
		is_climbing = true
		is_jumping = false
		wallslide_norm = 0
		last_walljump_norm = 0
		return
	
	if gamepad.move.y < -0.9 and is_grounded:
		gamepad.move.y = 0.0
		var things := interact_area.get_overlapping_bodies()
		things.append_array(interact_area.get_overlapping_areas())
		
		for thing in things:
			thing.propagate_call(&"receive_interact")
	
	if gamepad.move.y == 0.0:
		can_pound = true
	
	if (
			gamepad.move.y > 0.9
			and not is_grounded
			and velocity.y != 0.0
			and Global.emotions.has(&"depression")
			and can_pound
			and state != State.Grapple
			and state != State.Pound
			and state != State.Dash
	):
		can_pound = false
		state = State.Pound
		velocity.y = pound_speed
		vel_move = 0.0
		vel_extra = 0.0
		last_vel.x = 0.0
		velocity.x = 0.0
	
	if state != State.Pound and state != State.Grapple:
		process_movement(delta)
		process_gravity(delta)
		process_jump(delta)
		#process_wallslide(delta)
	
	if state == State.Grapple:
		grappling_time += delta
		var grapple_speed := grapple_speed_curve.sample_baked(grappling_time * Global.TPS)
		position.x = move_toward(position.x, grapple_target_x, grapple_speed * delta)
		grapple_line.points[1] = grapple_line.to_local(global_position + Vector2(0.0, -8.0))
		if absf(position.x - grapple_target_x) < grapple_min_distance or grappling_time > max_grapple_time:
			state = State.Fall
			grapple_gfx.hide()
			airborne_refresh()
	
	if gamepad.grapple.pressed and Global.emotions.has(&"love"):
		grapple_ray_cast.force_raycast_update()
		if grapple_ray_cast.is_colliding():
			velocity = Vector2.ZERO
			last_vel = Vector2.ZERO
			vel_move = 0.0
			vel_extra = 0.0
			state = State.Grapple
			grapple_target_x = grapple_ray_cast.get_collision_point().x
			grappling_time = 0.0
			grapple_gfx.show()
			grapple_gfx.position.x = grapple_target_x
			grapple_gfx.position.y = position.y - 8.0
	
	move(delta)


func process_state_dash(delta: float) -> void:
	collision_normal.disabled = true
	collision_dash.disabled = false
	
	dash_timer -= delta
	if dash_timer <= 0.0:
		state = State.Fall
		vel_move = move_speed * direction
		collision_normal.disabled = false
		collision_dash.disabled = true
		return
	
	var dash_duration := dash_distance_curve.max_domain
	var dash_distance_prev := dash_distance_curve.sample_baked(dash_duration - (dash_timer * Global.TPS))
	var dash_distance_next := dash_distance_curve.sample_baked(dash_duration - ((dash_timer + delta) * Global.TPS))
	var dash_delta := dash_distance_prev - dash_distance_next
	var hit := move_and_collide(Vector2(dash_delta * direction, 0.0), false, 0.08, true)
	last_vel = Vector2.ZERO
	velocity = Vector2.ZERO
	vel_extra = 0.0
	
	if (
		climb_area.get_overlapping_areas().size() + climb_area.get_overlapping_bodies().size() > 0
		and gamepad.move.y < 0.0
	):
		can_dash = true
		state = State.Climb
		is_climbing = true
		is_jumping = false
		wallslide_norm = 0
		last_walljump_norm = 0
		dash_timer = -1.0
		collision_normal.disabled = false
		collision_dash.disabled = true
		return
	
	if hit:
		# end dash early
		dash_timer = -1.0
		collision_normal.disabled = false
		collision_dash.disabled = true
		state = State.Fall


func process_state_climb(delta: float) -> void:
	if climb_area.get_overlapping_bodies().size() == 0 or (is_on_floor() and gamepad.move.y > 0.0):
		is_climbing = false
		state = State.Fall
		coyote_timer = climb_coyote_time / Global.TPS
		if gamepad.move.y < 0.0:
			apply_floor_snap()
			velocity.y = 0.0
		return
	
	can_dash = true
	vel_extra = 0.0
	velocity.y = gamepad.move.y * climb_speed_vertical
	vel_move = gamepad.move.x * climb_speed_horizontal
	
	if jump_buffer_timer > 0.0:
		state = State.Jump
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
		if coyote_timer > 0.0: # or else jump
			#SoundBank.play("jump", position)
			state = State.Jump
			is_jumping = true
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			
			velocity.y = -jump_velocity_max
			if wallslide_norm != 0:
				last_walljump_norm = wallslide_norm
				vel_extra = wallslide_norm * walljump_horizontal_speed
				wallslide_norm = 0
		elif can_double_jump and Global.emotions.has(&"joy"):
			state = State.DoubleJump
			can_double_jump = false
			jump_buffer_timer = 0.0
			vel_move = maxf(absf(vel_move), double_jump_move_speed) * direction
			# vel_extra = double_jump_extra_speed * direction
			velocity.y = -double_jump_velocity


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
	can_double_jump = true
	can_dash = true


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
	
	# SFX.event("death.player").at(self).play()
	
	respawn()


func respawn() -> void:
	modulate.a = 0.5
	z_index += 1000
	scale = Vector2.ONE * 0.75
	
	var spawn_position := respawn_point
	
	var delta := spawn_position - position
	
	var duration := 1.0
	
	var tween := create_tween()
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


var say_queue: Array[String] = []

func say(text: String) -> void:
	say_queue.append(text)
	
	if say_queue.size() > 1: return
	
	while say_queue.size() > 0:
		text = say_queue.front()
		
		var lines := text.split("\n\n", false)
		
		for line in lines:
			var label := talk_label.duplicate()
			label.text = "[wave][center]" + line
			label.visible_characters = 0
			add_child(label)
			label.show()
			
			var tween := create_tween()
			tween.tween_property(label, ^"visible_characters", line.length(), line.length() * 0.04)
			tween.tween_callback(Util.noop).set_delay(3.0)
			await tween.finished
			tween = create_tween()
			tween.tween_property(label, ^"position:y", -8.0, 1.0).as_relative().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(label, ^"modulate:a", 0.0, 0.5)
			tween.tween_callback(label.queue_free)
		
		say_queue.pop_front()

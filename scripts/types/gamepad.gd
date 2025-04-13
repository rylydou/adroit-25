class_name Gamepad extends RefCounted


const DEVICE_AUTO = -2
const DEVICE_KEYBOARD = -1


class JoyInfo:
	var id := 0
	var name := ""
	var guid := ""
	var is_known := false
	var connected := false
	
	static func from_id(id: int) -> JoyInfo:
		var info := JoyInfo.new()
		info.id = id
		info.name = Input.get_joy_name(id)
		info.guid = Input.get_joy_guid(id)
		info.is_known = Input.is_joy_known(id)
		return info


static var joys: Dictionary = {}
static var gamepads: Array[Gamepad] = []

static var keyboard := Gamepad.create(DEVICE_KEYBOARD)


static func _static_init() -> void:
	gamepads.append(keyboard)


static func create(device: int) -> Gamepad:
	var gamepad := Gamepad.new()
	gamepad.device = device
	return gamepad


# ---------------------------------------- #


@export var device := 0
@export var deadzone := 0.5
@export var move_deadzone := 0.35
@export var crouch_threshold := 0.7
@export var move_snap_amount := 1.3333
@export var aim_deadzone := 0.5
@export var trigger_deadzone := 0.5


var enabled := true


var move := Vector2.ZERO

var jump := Btn.new()
var crouch := Btn.new()

var punch := Btn.new()
var dash := Btn.new()
var grapple := Btn.new()

var self_destruct := Btn.new()


func duplicate() -> Gamepad:
	return Gamepad.create(self.device)


func poll(delta: float) -> void:
	if not enabled:
		poll_gamepad(delta, 100)
		return
	
	match Global.input_method:
		Global.InputMethod.ArrowKeys:
			poll_arrows(delta)
		Global.InputMethod.WASD:
			poll_wasd(delta)
		Global.InputMethod.Gamepad:
			poll_gamepad(delta, 0)


func poll_gamepad(delta: float, device: int) -> void:
	move.x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	move.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	
	move.x += float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT))
	move.y += float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP))
	
	move.x = clampf(move.x, -1.0, 1.0)
	move.y = clampf(move.y, -1.0, 1.0)
	
	# apply deadzone to account for shitty controller joysticks
	var move_length_squared := move.length_squared()
	if move_length_squared < move_deadzone ** 2.0:
		move = Vector2.ZERO
	else:
		# remap move vector to hide the deadzone
		# 25...100 -> 0...100
		var move_length := sqrt(move_length_squared)
		move = (move / move_length) * ((move_length - move_deadzone) / (1.0 - move_deadzone))
	
	move = round(move.normalized() * move_snap_amount)
	
	jump.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_A)
	), delta)
	
	crouch.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
			or Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) > crouch_threshold
	), delta)
	
	punch.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
	), delta)
	dash.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_X)
	), delta)
	grapple.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_B)
	), delta)
	
	self_destruct.track(Input.is_joy_button_pressed(device, JOY_BUTTON_BACK), delta)


func poll_arrows(delta: float) -> void:
	var right := float(
			Input.is_physical_key_pressed(KEY_RIGHT)
	)
	var left := float(
			Input.is_physical_key_pressed(KEY_LEFT)
	)
	move.x = right - left
	
	var down := float(
			Input.is_physical_key_pressed(KEY_DOWN)
	)
	var up := float(
			Input.is_physical_key_pressed(KEY_UP)
	)
	move.y = down - up
	
	jump.track((
			Input.is_physical_key_pressed(KEY_Z)
	), delta)
	crouch.track((
			Input.is_physical_key_pressed(KEY_DOWN)
	), delta)
	
	punch.track(
			Input.is_physical_key_pressed(KEY_SPACE)
	, delta)
	dash.track(
			Input.is_physical_key_pressed(KEY_X)
	, delta)
	grapple.track(
			Input.is_physical_key_pressed(KEY_C)
	, delta)
	
	self_destruct.track(Input.is_key_label_pressed(KEY_DELETE), delta)


func poll_wasd(delta: float) -> void:
	var right := float(
			Input.is_physical_key_pressed(KEY_D)
	)
	var left := float(
			Input.is_physical_key_pressed(KEY_A)
	)
	move.x = right - left
	
	var down := float(
			Input.is_physical_key_pressed(KEY_S)
	)
	var up := float(
			Input.is_physical_key_pressed(KEY_W)
	)
	move.y = down - up
	
	jump.track((
			Input.is_physical_key_pressed(KEY_Z)
			# or Input.is_physical_key_pressed(KEY_SPACE)
	), delta)
	crouch.track((
			Input.is_physical_key_pressed(KEY_S)
	), delta)
	
	punch.track(
			Input.is_physical_key_pressed(KEY_SPACE)
	, delta)
	dash.track(
			Input.is_physical_key_pressed(KEY_E)
			or Input.is_physical_key_pressed(KEY_SHIFT)
	, delta)
	grapple.track(
			Input.is_physical_key_pressed(KEY_F)
			or Input.is_physical_key_pressed(KEY_CTRL)
			or Input.is_physical_key_pressed(KEY_META)
			or Input.is_physical_key_pressed(KEY_ALT)
	, delta)
	
	self_destruct.track(Input.is_key_label_pressed(KEY_DELETE), delta)

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


static func _joy_connection_changed(id: int, connected: bool) -> void:
	if connected:
		var info := JoyInfo.from_id(id)
		info.connected = true
		joys[id] = info
		print("[Input] ",info.name," connected as ",id)
		# if info.is_known:
		# 	Toast.show(str("Connected: ",info.name))
		# else:
		# 	Toast.show(str("Unknown Gamepad: ",info.name))
		var gamepad := Gamepad.create(id)
		gamepads.append(gamepad)
		# Bus.gamepad_connected.emit(gamepad)
		return
	
	if not joys.has(id): return
	var info: JoyInfo = joys[id]
	info.connected = false
	print("[Input] ",info.name," disconnected from ",id)
	# Toast.show(str("Disconnected: ",info.name))
	var index := Util.index_of(gamepads, func(gamepad: Gamepad) -> bool: return gamepad.device == id)
	var gamepad := gamepads[index]
	# Bus.gamepad_disconnected.emit(gamepad)
	gamepads.remove_at(index)


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


var any := Btn.new()

var menu_ok := Btn.new()
var menu_back := Btn.new()
var menu_pause := Btn.new()
var menu_left := Btn.turbo()
var menu_right := Btn.turbo()
var menu_up := Btn.turbo()
var menu_down := Btn.turbo()

var move := Vector2.ZERO
var aim := Vector2.ZERO

var jump := Btn.new()
var crouch := Btn.new()

var punch := Btn.new()
var dash := Btn.new()
var grapple := Btn.new()

var self_destruct := Btn.new()


func duplicate() -> Gamepad:
	return Gamepad.create(self.device)


func get_connection() -> bool:
	match device:
		-2: return true
		-1: return true
	if Gamepad.joys.has(device):
		return Gamepad.joys[device].connected
	return false


func get_name() -> String:
	match device:
		-2: return "Auto"
		-1: return "Keyboard"
	if not Gamepad.joys.has(device):
		return Gamepad.joys[device].name
	return "Unknown"


func vibrate(weak: float, strong: float, duration: float) -> void:
	Input.start_joy_vibration(device, weak, strong, duration)


func poll(delta: float) -> void:
	match device:
		-2:
			if Input.is_joy_known(0):
				var _device := device
				device = 0
				poll_gamepad(delta)
				device = _device
			else:
				poll_keyboard(delta)
		-1:
			poll_keyboard(delta)
		_:
			poll_gamepad(delta)


func poll_gamepad(delta: float) -> void:
	any.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_START)
			or Input.is_joy_button_pressed(device, JOY_BUTTON_BACK)
			or Input.is_joy_button_pressed(device, JOY_BUTTON_A)
			or Input.is_joy_button_pressed(device, JOY_BUTTON_B)
			or Input.is_joy_button_pressed(device, JOY_BUTTON_X)
			or Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
	), delta)
	
	menu_ok.track(Input.is_joy_button_pressed(device, JOY_BUTTON_B), delta)
	menu_back.track(Input.is_joy_button_pressed(device, JOY_BUTTON_A), delta)
	menu_pause.track(Input.is_joy_button_pressed(device, JOY_BUTTON_START), delta)
	
	menu_left.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X) <= -deadzone
	), delta)
	menu_right.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X) >= +deadzone
	), delta)
	menu_up.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) <= -deadzone
	), delta)
	menu_down.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) >= +deadzone
	), delta)
	
	move.x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	move.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	aim.x = Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
	aim.y = Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
	
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


func poll_keyboard(delta: float) -> void:
	any.track((
			Input.is_key_pressed(KEY_SPACE)
			or Input.is_key_pressed(KEY_ENTER)
			or Input.is_key_pressed(KEY_E)
	), delta)
	
	menu_ok.track((
			Input.is_physical_key_pressed(KEY_E)
			or Input.is_physical_key_pressed(KEY_SPACE)
			or Input.is_physical_key_pressed(KEY_ENTER)
	), delta)
	menu_back.track((
			Input.is_physical_key_pressed(KEY_Q)
			or Input.is_physical_key_pressed(KEY_BACKSPACE)
			or Input.is_physical_key_pressed(KEY_ESCAPE)
	), delta)
	menu_pause.track(Input.is_key_label_pressed(KEY_ESCAPE), delta)
	
	menu_left.track((
			Input.is_physical_key_pressed(KEY_A)
			or Input.is_physical_key_pressed(KEY_LEFT)
	), delta)
	menu_right.track((
			Input.is_physical_key_pressed(KEY_D)
			or Input.is_physical_key_pressed(KEY_RIGHT)
	), delta)
	menu_up.track((
			Input.is_physical_key_pressed(KEY_W)
			or Input.is_physical_key_pressed(KEY_UP)
	), delta)
	menu_down.track((
			Input.is_physical_key_pressed(KEY_S)
			or Input.is_physical_key_pressed(KEY_DOWN)
	), delta)
	
	var right := float(
			Input.is_physical_key_pressed(KEY_D)
			or Input.is_physical_key_pressed(KEY_RIGHT)
	)
	var left := float(
			Input.is_physical_key_pressed(KEY_A)
			or Input.is_physical_key_pressed(KEY_LEFT)
	)
	move.x = right - left
	
	var down := float(
			Input.is_physical_key_pressed(KEY_S)
			or Input.is_physical_key_pressed(KEY_DOWN)
	)
	var up := float(
			Input.is_physical_key_pressed(KEY_W)
			or Input.is_physical_key_pressed(KEY_UP)
	)
	move.y = down - up
	
	jump.track((
			Input.is_physical_key_pressed(KEY_Z)
			# or Input.is_physical_key_pressed(KEY_SPACE)
	), delta)
	crouch.track((
			Input.is_physical_key_pressed(KEY_DOWN)
			# or Input.is_physical_key_pressed(KEY_S)
	), delta)
	
	punch.track(
			Input.is_physical_key_pressed(KEY_SPACE)
	, delta)
	dash.track(
			Input.is_physical_key_pressed(KEY_X)
			# or Input.is_physical_key_pressed(KEY_E)
			# or Input.is_physical_key_pressed(KEY_SHIFT)
	, delta)
	grapple.track(
			Input.is_physical_key_pressed(KEY_C)
			or Input.is_physical_key_pressed(KEY_F)
			# or Input.is_physical_key_pressed(KEY_CTRL)
	, delta)
	
	self_destruct.track(Input.is_key_label_pressed(KEY_DELETE), delta)

class_name Global extends RefCounted


const TPS := 60.0

static var gravity := 368.64
static var gravity_scale := 1.0
static var debug_physics := false
static var emotions: Array[StringName] = []


enum InputMethod {
	ArrowKeys,
	WASD,
	Gamepad,
}
static var input_method := InputMethod.ArrowKeys


const input_translations := {
	InputMethod.ArrowKeys: {
		"{left}": "Left Arrow",
		"{right}": "Right Arrow",
		"{up}": "Up Arrow",
		"{down}": "Down Arrow",
		"{jump}": "Z",
		"{pound}": "Down Arrow",
		"{dash}": "X",
		"{grapple}": "C",
	},
	InputMethod.WASD: {
		"{left}": "A",
		"{right}": "D",
		"{up}": "W",
		"{down}": "S",
		"{jump}": "Space Bar",
		"{pound}": "S",
		"{dash}": "Shift or E",
		"{grapple}": "Ctrl or F",
	},
	InputMethod.Gamepad: {
		"{left}": "Left",
		"{right}": "Right",
		"{up}": "Up",
		"{down}": "Down",
		"{jump}": "A",
		"{pound}": "Y",
		"{dash}": "X",
		"{grapple}": "B",
	},
}

static func translate_button_prompts(text: String) -> String:
	var trans = input_translations[input_method]
	for prompt in trans:
		text = text.replace(prompt, trans[prompt])
	
	return text
	


# === Singletons ===
static var player: PlayerCharacter
static var current_room: Room
static var camera: Camera


## If false then the game will crash when encountering errors
static var carefree := not OS.is_debug_build()

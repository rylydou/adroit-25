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
		"{left}": "←",
		"{right}": "→",
		"{up}": "↑",
		"{down}": "↓",
		"{pound}": "↓",
		"{jump}": "Z",
		"{dash}": "X",
		"{grapple}": "C",
		"{punch}": "Space Bar",
	},
	InputMethod.WASD: {
		"{left}": "A",
		"{right}": "D",
		"{up}": "W",
		"{down}": "S",
		"{pound}": "S",
		"{jump}": "Space Bar",
		"{dash}": "Shift or E",
		"{grapple}": "Ctrl or Q",
		"{punch}": "F",
	},
	InputMethod.Gamepad: {
		"{left}": "←",
		"{right}": "→",
		"{up}": "↑",
		"{down}": "↓",
		"{pound}": "↓",
		"{jump}": "A",
		"{dash}": "X",
		"{grapple}": "B",
		"{punch}": "Y",
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

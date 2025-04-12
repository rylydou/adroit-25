class_name Global extends RefCounted


const TPS := 60.0

static var gravity := 368.64
static var gravity_scale := 1.0
static var debug_physics := false
static var emotions: Array[StringName] = []


# === Singletons ===
static var player: PlayerCharacter
static var current_room: Room
static var camera: Camera


## If false then the game will crash when encountering errors
static var carefree := not OS.is_debug_build()

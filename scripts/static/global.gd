class_name Global extends RefCounted


const TPS := 60.0

static var gravity := 368.64
static var gravity_scale := 1.0
static var debug_physics := true
static var emotions: Array[StringName] = []

# const ground_dec := 128.0
# const ground_smooth := 10.0

# const air_dec := 0.0
# const air_smooth := 0.0


static var current_room: Room



## If false then the game will crash when encountering errors
static var carefree := not OS.is_debug_build()

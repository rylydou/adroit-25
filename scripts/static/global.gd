class_name Global extends RefCounted


const TPS := 60.0

static var gravity := 368.64
static var gravity_scale := 1.0
static var debug_physics := true
#FEAR, JOY, DEPRESSION, ANGER, LOVE
static var fear := false
static var joy := false
static var depression := false
static var anger := false
static var love := false

static var emotions : Array[String] = []
# const ground_dec := 128.0
# const ground_smooth := 10.0

# const air_dec := 0.0
# const air_smooth := 0.0



## If false then the game will crash when encountering errors
static var carefree := not OS.is_debug_build()

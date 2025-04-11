class_name Global extends RefCounted


const TPS := 60.0

# static var gravity := 368.64
# static var gravity_scale := 1.0

# const ground_dec := 128.0
# const ground_smooth := 10.0

# const air_dec := 0.0
# const air_smooth := 0.0


## If false then the game will crash when encountering errors
static var carefree := not OS.is_debug_build()


static var player_colors: Array[Vector2] = []


static func _static_init() -> void:
	var colors_files := FileAccess.open("res://resources/player_colors.wsv", FileAccess.READ)
	colors_files.get_line()
	while true:
		var line := Util.get_wsv_line(colors_files)
		if line.is_empty(): break
		if line.size() < 2: continue
		
		player_colors.append(Vector2(
				line[0].to_float() / 360.0,
				line[1].to_float() / 100.0
		))

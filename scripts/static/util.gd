class_name Util extends RefCounted


static func noop() -> void:
	pass


static func queue_free_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


static func timer_ticks(node: Node, ticks: float, use_physics := true) -> void:
	await timer_sec(node, ticks / Global.TPS, use_physics)


static func timer_sec(node: Node, delay: float, use_physics := true) -> void:
	var tween := node.create_tween()
	if use_physics:
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_callback(noop).set_delay(delay)
	await tween.finished


static func get_children_in_group(node: Node, group: StringName) -> Array[Node]:
	var children: Array[Node] = []
	
	for child in node.get_children():
		if child.is_in_group(group):
			children.append(child)
		children.append_array(get_children_in_group(child, group))
	
	return children


static func clamp_str(string: String, max_length: int) -> String:
	return string.substr(0, mini(string.length(), max_length))


static func index_of(arr: Array, f: Callable) -> int:
	for index in arr.size():
		var item: Variant = arr[index]
		if f.call(item):
			return index
	return -1


static func print_dir(path: String, indent := 0) -> void:
	print("\t".repeat(indent) + path.get_file() + "/")
	for dirname in DirAccess.get_directories_at(path):
		print_dir(path.path_join(dirname), indent + 1)
	
	for filename in DirAccess.get_files_at(path):
		print("\t".repeat(indent + 1) + filename)


static func alpha(color: Color, a: float) -> Color:
	return Color(color.r, color.g, color.b, a)


## Returns default if curve is null
static func sample_curve(curve: Curve, offset: float, default := 0.0) -> float:
	if not curve: return default
	return curve.sample_baked(offset)


static func format_stack_trace(trace_line: Dictionary) -> String:
	var source: String = trace_line[&"source"]
	var line: int = trace_line[&"line"]
	# var function: String = trace_line[&"function"]
	return str(source.get_file(),":",line)


static func format_stack_trace_full(trace_line: Dictionary) -> String:
	var source: String = trace_line[&"source"]
	var line: String = trace_line[&"line"]
	var function: String = trace_line[&"function"]
	return str(source,":",line,":",function,"()")


static func get_lines(file: FileAccess) -> PackedStringArray:
	var lines := PackedStringArray()
	while not file.eof_reached():
		lines.append(file.get_line())
	return lines


static func get_wsv_lines(file: FileAccess) -> Array[Array]:
	var lines: Array[Array] = []
	while true:
		var line := get_wsv_line(file)
		if line.is_empty(): break
		lines.append(line)
	return lines


static func get_wsv_line(file: FileAccess) -> PackedStringArray:
	var line := ""
	
	while line.is_empty():
		if file.eof_reached():
			return PackedStringArray()
		
		line = file.get_line().strip_edges()
		
		if line.begins_with("#"):
			continue
	
	var parts := PackedStringArray()
	var start_index := 0
	var in_whitespace := false
	for index in line.length():
		var ch := line[index]
		var is_whitepace := ch.strip_edges().is_empty()
		
		if is_whitepace:
			if not in_whitespace:
				parts.append(line.substr(start_index, index))
				in_whitespace = true
			continue
		
		if in_whitespace:
			in_whitespace = false
			start_index = index
	
	if not in_whitespace:
		parts.append(line.substr(start_index))
	
	return parts


static func set_color_scheme(node: Node, color: Vector2) -> void:
	var hue := color.x
	var sat := color.y
	set_color_fg_bg(node,
			Color.from_ok_hsl(hue, sat, 0.80),
			Color.from_ok_hsl(hue, sat, 0.30),
	)


static func set_color_fg_bg(node: Node, bg: Color, fg: Color) -> void:
	_set_controls_color(get_children_in_group(node, &"clr_bg"), bg)
	_set_controls_color(get_children_in_group(node, &"clr_fg"), fg)


static func _set_controls_color(controls: Array[Node], color: Color) -> void:
	for control in controls:
		control.self_modulate = color

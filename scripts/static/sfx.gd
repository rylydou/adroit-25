class_name SFX extends RefCounted


const SPEC_META_KEY = "sfx_spec"


class Instance:
	var fmod_event: FmodEvent
	
	func play() -> Instance:
		fmod_event.start()
		return self
	
	func param(key: String, value: float) -> Instance:
		fmod_event.set_parameter_by_name(key, value)
		return self
	
	func at(thing: CanvasItem) -> Instance:
		fmod_event.set_2d_attributes(thing.get_global_transform())
		return self
	
	func fade_out() -> Instance:
		return self
	
	func stop() -> void:
		fmod_event.stop(0)
		fmod_event.release()
	
	func set_pause(state: bool) -> void:
		fmod_event.paused = state


static var enable_sound_cache := not OS.is_debug_build()
static var cache: Dictionary = {}


static func get_event_path(event_name: String) -> String:
	event_name = "event:/" + event_name
	
	while not FmodServer.check_event_path(event_name):
		if not event_name.contains("."):
			event_name = "event:/_DNE"
			break
		
		event_name = event_name.get_basename()
	
	return event_name


static func event(event_name: String, specifier: Variant = null) -> Instance:
	if specifier is Object and specifier.has_meta(SPEC_META_KEY):
		specifier = specifier.get_meta(SPEC_META_KEY)
	
	if specifier and (specifier is String or specifier is StringName):
		event_name = StringName(event_name + "." + specifier)
	
	var event_path := ""
	
	if enable_sound_cache:
		event_path = cache.get(event_name)
		if not event_path:
			# cache miss
			event_path = get_event_path(event_name)
			cache[event_name] = event_path
	else:
		event_path = get_event_path(event_name)
	
	var instance := Instance.new()
	instance.fmod_event = FmodServer.create_event_instance(event_path)
	return instance

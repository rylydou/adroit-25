extends CanvasItem


class Result:
	var command: DEV_Command
	var score := -1.0


const RECENT_COMMANDS_FILE := "user://devtools_command_history.txt"


@export var recent_command_count := 10

@export var shortcut: Shortcut


@onready var input_edit: LineEdit = %"Command Input"
@onready var command_info: RichTextLabel = %"Command Info"
@onready var command_info_container: Control = %"Command Info Container"
@onready var item_list: ItemList = %"Command List"
@onready var status_label: Label = %"Status Label"


var results: Array[Result] = []
var recent_command_ids: Array[StringName] = []


func _enter_tree() -> void:
	hide()
	load_recent_commands()


func _ready() -> void:
	input_edit.text_changed.connect(update.unbind(1))
	input_edit.text_submitted.connect(execute.unbind(1))
	input_edit.gui_input.connect(_input_gui_input)
	
	item_list.item_selected.connect(execute_item)
	item_list.item_activated.connect(execute_item)


func _input(event: InputEvent) -> void:
	if shortcut.matches_event(event) and event.is_pressed():
		get_viewport().set_input_as_handled()
		toggle_me()
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		if visible:
			get_viewport().set_input_as_handled()
			hide()


func toggle_me() -> void:
	if visible:
		hide()
		return
	
	show()
	input_edit.grab_focus()
	update()


func update() -> void:
	var search := DEV_Util.cleanup_string(input_edit.text)
	
	results.clear()
	
	if search.is_empty():
		for command_name in recent_command_ids:
			# check if command still exists -- if not then delete it
			if not DevTools.commands_by_id.has(command_name):
				recent_command_ids.erase(command_name)
				continue
			
			var command: DEV_Command = DevTools.commands_by_id[command_name]
			var result := Result.new()
			result.command = command
			results.append(result)
		
		_update_results("No recent commands...")
		status_label.text = "(recent commands)"
		return
	
	for command in DevTools.commands:
		var score := DEV_Util.calculate_score(command.id, search, recent_command_ids)
		
		if score > 0:
			var result := Result.new()
			result.command = command
			result.score = score
			_add_result(result)
	
	_update_results("No matching commands...")


func _add_result(result: Result) -> void:
	for index in results.size():
		var result_at_index := results[index]
		if result_at_index.score < result.score:
			results.insert(index, result)
			return
	
	# results.push_front(result)
	results.append(result)


func _update_results(empty_prompt: String) -> void:
	item_list.clear()
	
	if results.is_empty():
		var list_item_id := item_list.add_item(empty_prompt, null, false)
		item_list.set_item_selectable(list_item_id, false)
		item_list.set_item_disabled(list_item_id, true)
		status_label.text = ""
		_update_selected_command()
		return
	
	for result in results:
		# var list_item_id := item_list.add_item("%s (%.2f)" % [result.command.name, result.score])
		var list_item_id := item_list.add_item(result.command.name)
	
	status_label.text = str(results.size())
	if results.size() == 1:
		status_label.text += " match"
	else:
		status_label.text += " matches"
	
	item_list.select(0)
	_update_selected_command()
	
		# item_list.set_item_disabled(list_item_id, true)


func _add_command_entry(command: DEV_Command) -> int:
	var item_id := item_list.add_item(command.name)
	return item_id


func execute() -> void:
	var selection := item_list.get_selected_items()
	
	if selection.size() <= 0:
		execute_item(0)
		return
	
	execute_item(selection[0])


func execute_item(index: int) -> void:
	if index < 0 or index >= results.size(): return
	
	var result := results[index]
	result.command.callback.call()
	recent_command_ids.erase(result.command.id)
	recent_command_ids.push_front(result.command.id)
	input_edit.text = ""
	hide()


func _input_gui_input(event: InputEvent):
	if not event.is_pressed(): return
	
	var key_event := event as InputEventKey
	if key_event and key_event.keycode == KEY_DOWN:
		get_viewport().set_input_as_handled()
		
		var selection := item_list.get_selected_items()
		if selection.size() <= 0 or selection[0] >= item_list.item_count - 1:
			item_list.select(0)
		else:
			item_list.select(selection[0] + 1)
		
		_update_selected_command()
		return
	
	if key_event and key_event.keycode == KEY_UP:
		get_viewport().set_input_as_handled()
		
		var selection := item_list.get_selected_items()
		if selection.size() <= 0 or selection[0] <= 0:
			item_list.select(item_list.item_count - 1)
		else:
			item_list.select(selection[0] - 1)
		
		_update_selected_command()
		return


func _update_selected_command() -> void:
	var selection := item_list.get_selected_items()
	
	if selection.size() < 1:
		command_info_container.hide()
		return
	
	var result := results[selection[0]]
	var command := result.command
	command_info.text = "%s" % command.description
	
	if not command.parameters.is_empty():
		command_info.text += "\n\nParameters:\n- %s" % "\n- ".join(command.parameters.map(func(x): return x.split("|")[0]))
	
	item_list.ensure_current_is_visible()
	
	command_info.text += "\n\nScore: %.2f" % result.score
	
	command_info_container.show()


func load_recent_commands() -> void:
	print("Loading recent commands...")
	
	recent_command_ids.clear()
	
	if not FileAccess.file_exists(RECENT_COMMANDS_FILE):
		return
	
	var file := FileAccess.open(RECENT_COMMANDS_FILE, FileAccess.READ)
	
	while true:
		if file.eof_reached():
			break
		
		var line := file.get_line()
		recent_command_ids.append(line)


func save_recent_commands() -> void:
	print("Saving recent commands...")
	
	var file := FileAccess.open(RECENT_COMMANDS_FILE, FileAccess.WRITE)
	
	for index in mini(recent_command_count, recent_command_ids.size()): # only save most recent 10 commands
		var recent_command_name := recent_command_ids[index]
		file.store_line(recent_command_name)
	
	file.close()



func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_recent_commands()

extends CanvasLayer


const ESSENTIAL_COMMANDS := preload("res://addons/devtools/scripts/essential_commands.gd")


@export var register_essential_commands := true


var commands: Array[DEV_Command] = []
var commands_by_id: Dictionary[StringName, DEV_Command] = {}


func _enter_tree() -> void:
	if register_essential_commands:
		ESSENTIAL_COMMANDS.register_my_commands()


func new_command(name: StringName) -> DEV_Command:
	var command := DEV_Command.new()
	command.named(name)
	
	commands.append(command)
	commands_by_id[command.id] = command
	
	return command


func register_command(command: DEV_Command) -> DEV_Command:
	commands.append(command)
	commands_by_id[command.id] = command
	return command

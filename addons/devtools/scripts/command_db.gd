class_name DEV_CommandDB extends RefCounted


var commands: Array[DEV_Command] = []
var command_by_alias: Dictionary = {}


func new_command(name: StringName) -> DEV_Command:
	var command := DEV_Command.new()
	commands.append(command)
	command.db = self
	return command.named(name)


func register_command(command: DEV_Command) -> DEV_Command:
	commands.append(command)
	
	return command

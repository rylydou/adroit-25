class_name DEV_Command extends RefCounted


static func unimplemented() -> void:
	push_warning("This command has not been implemented yet.")


var id := "unknown"
var name := "Unknown Command"
var callback: Callable = unimplemented

var description := ""

var shortcuts: Array[Shortcut] = []
var parameters: Array[String] = []

## True if the command is current in the process of being made.
var _is_composing := true


## Defines the code that will run when this command is executed.
func exec(callable: Callable) -> DEV_Command:
	_is_composing = false
	self.callback = callable
	return self


## Defines the name of this command.
func named(name: String) -> DEV_Command:
	# assert(_is_composing, "Cannot modify command after [code]exec()[/code] has been called.")
	self.name = name
	self.id = DEV_Util.cleanup_string(name)
	return self


func describe(description: String) -> DEV_Command:
	self.description = description
	return self


func params(params: Array) -> DEV_Command:
	self.parameters.assign(params)
	return self


## Adds a hot-key (aka shortcut) to this command.
func hkey(hkey_string: String) -> DEV_Command:
	shortcut(ShortcutUtil.from_string(hkey_string))
	return self


## Adds a keyboard shortcut (aka hot-key) to this command.
## It is recommended to instead use [code]hkey(String)[/code] instead.
func shortcut(shortcut: Shortcut) -> DEV_Command:
	# assert(_is_composing, "Cannot modify command after [code]exec()[/code] has been called.")
	shortcuts.append(shortcut)
	return self

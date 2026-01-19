extends BaseCommand
class_name ReturnCommand

func get_command_name() -> String:
	return "return"

func get_description() -> String:
	return "call元の位置に戻ります。"

func execute(params: Dictionary, context: Dictionary) -> void:
	var sm = context.get("scenario_manager")
	if sm:
		sm.return_from_call()

func requires_wait() -> bool:
	return false	

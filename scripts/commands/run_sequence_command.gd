extends BaseCommand
class_name RunSequenceCommand
func get_command_name() -> String: return "run_sequence"
func execute(params: Dictionary, context: Dictionary) -> void:
	var gm = context.get("game_manager")
	# IDを取得して登録時に渡す
	var id = params.get("id", "")
	var runner = SequenceRunner.new(params.get("commands", []), context)
	
	if gm:
		# GameManager側で register_async_task(runner, id) できるように修正が必要
		# (GameManagerの register_async_task の引数に owner_id を追加してください)
		gm.register_async_task(runner, id) 
		runner.start()
func requires_wait() -> bool: return false

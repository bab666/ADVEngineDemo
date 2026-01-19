extends BaseCommand
class_name WaitCommand

func get_command_name() -> String:
	return "wait"

func get_description() -> String:
	return "指定時間待機します。パラメータ: time=ミリ秒 (例: @wait time=2000)"

func execute(params: Dictionary, context: Dictionary) -> void:
	var time_ms = params.get("time", 1000)
	var time_sec = time_ms / 1000.0
	
	# GameManagerの待機機能を利用
	context.game_manager.start_wait(time_sec)

func requires_wait() -> bool:
	return true # 自動進行を止める

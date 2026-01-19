extends BaseCommand
class_name WaitCommand

func get_command_name() -> String:
	return "wait"

func execute(params: Dictionary, context: Dictionary) -> void:
	var time_ms = params.get("time", 1000)
	var time_sec = time_ms / 1000.0
	
	# ★修正: 非同期モードならTweenを使って待機する
	if context.get("is_async", false):
		var gm = context.get("game_manager")
		if gm:
			var t = gm.create_tween()
			t.tween_interval(time_sec)
			context["current_tween"] = t # Runnerに待たせる
	else:
		context.game_manager.start_wait(time_sec)

func requires_wait() -> bool:
	return true

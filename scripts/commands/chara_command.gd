extends BaseCommand
class_name CharaCommand

# 実行時に待機が必要かどうかを保持するフラグ
var _should_wait: bool = false

func get_command_name() -> String:
	return "chara"

func get_description() -> String:
	return "キャラ表示: @chara id expression [pos:x,y] [time=ms] [wait=true/false]..."

func execute(params: Dictionary, context: Dictionary) -> void:
	var char_id = params.get("id", "")
	var expression = params.get("expression", "")
	
	if char_id.is_empty():
		push_warning("ID指定なし")
		return
	
	var display = context.get("character_display")
	if not display: return
	
	# 拡張表示メソッドを実行
	display.show_character_ex(char_id, expression, params)
	
	print("Chara表示: %s %s params=%s" % [char_id, expression, params])
	
	# wait判定
	var wait = params.get("wait", true)
	var time_ms = params.get("time", 1000)
	
	_should_wait = (wait and time_ms > 0)
	
	if _should_wait:
		# GameManagerに待機を依頼する
		context.game_manager.start_wait(time_ms / 1000.0)

func requires_wait() -> bool:
	# execute内で決定したフラグを返す
	return _should_wait

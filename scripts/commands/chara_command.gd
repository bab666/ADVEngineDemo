extends BaseCommand
class_name CharaCommand

func get_command_name() -> String:
	return "chara"

func get_description() -> String:
	return "キャラ表示: @chara id expression [pos:x,y,z] [time=ms]..."

func execute(params: Dictionary, context: Dictionary) -> void:
	var char_id = params.get("id", "")
	var expression = params.get("expression", "")
	
	if char_id.is_empty():
		push_warning("ID指定なし")
		return
	
	var display = context.get("character_display")
	if not display: return
	
	# ★修正: 拡張メソッド show_character_ex を呼び出す
	var tween = display.show_character_ex(char_id, expression, params)
	
	print("Chara表示: %s %s" % [char_id, expression])
	
	# wait処理 (簡易版)
	var wait = params.get("wait", true)
	var time = params.get("time", 1000)
	
	if wait and time > 0:
		# シナリオ進行を待たせるためにタイマー待機
		await display.get_tree().create_timer(time / 1000.0).timeout

func requires_wait() -> bool:
	return false 
	# execute内でawaitしているので、システム側の待機はfalseにしておく
	# (システム側で待機させたい場合は true に戻して execute を即終了させる設計変更が必要)

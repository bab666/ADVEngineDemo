extends BaseCommand
class_name WindowCommand

func get_command_name() -> String:
	return "window"

func get_description() -> String:
	return "メッセージを表示するウインドウを切り替えます。パラメータ: ID (例: @window narrator)"

func execute(params: Dictionary, context: Dictionary) -> void:
	# 引数の最初のキーをIDとして取得、または id=... 指定
	var window_id = params.get("id", "")
	
	# @window narrator のように書いた場合、paramsのキーに "narrator" が入ることがあるため
	# id指定がなければ最初のキーを採用する簡易ロジック
	if window_id.is_empty():
		for key in params.keys():
			if key != "type":
				window_id = key
				break
	
	if window_id.is_empty():
		window_id = "default"
	
	var wm = context.get("window_manager")
	if wm:
		wm.set_current_window(window_id)

func requires_wait() -> bool:
	return false

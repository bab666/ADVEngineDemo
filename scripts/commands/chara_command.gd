# D:\Works\Godot\spelLDemo\scripts\commands\chara_command.gd
extends BaseCommand
class_name CharaCommand

func get_command_name() -> String:
	return "chara"

func get_description() -> String:
	return "キャラ表示: @chara id expression [pos:x,y,z] [time=ms] [scale=1.0] [wait=true]..."

func execute(params: Dictionary, context: Dictionary) -> void:
	var char_id = params.get("id", "")
	var expression = params.get("expression", "")
	
	if char_id.is_empty():
		push_warning("ID指定なし")
		return
	
	var display = context.get("character_display")
	if not display: return
	
	# 拡張表示メソッドを実行し、Tweenを受け取る
	var tween = display.show_character_ex(char_id, expression, params)
	
	print("Chara表示: %s %s params=%s" % [char_id, expression, params])
	
	# wait=true なら完了を待つ
	var wait = params.get("wait", true)
	if wait and tween and tween.is_valid():
		# ここで待機するには execute を async にする必要があるが、
		# BaseCommandの仕様上 execute は void なので、
		# 実際には ScenarioManager 側で待機制御が必要。
		# ★簡易的な対応として、このコマンド自体が「待機が必要」とフラグを返し、
		# シグナルやタイマーで待つ設計にするのが一般的。
		
		# 今回のシステムでは execute_command が bool (requires_wait) を返す仕組み。
		# しかしアニメーション完了動的待機は create_timer で代用する。
		if params.has("time"):
			await display.get_tree().create_timer(params.get("time") / 1000.0).timeout

# 今回の改修では execute 内で await しても、呼び出し元が await していないと待てない。
# ScenarioManager の構造上、requires_wait() で true を返すと「入力待ち」になるが、
# 「演出待ち」は自動で進んでほしい。
# なので、ここでは簡易的に「即時終了」扱いにするか、システム全体で演出待ちを入れる必要がある。
# ユーザー要望の「wait=trueなら完了を待つ」を実現するため、
# GameManager側でこのコマンドの完了を待てるような設計拡張が必要だが、
# ここでは「指定時間分だけスリープする」処理を挟むことで擬似的に実現する。

	# 注意: execute自体が await しても、呼び出し元が待ってくれない場合があるため
	# 本格的な演出待ちはGameManager/CommandRegistryの改修が必要。
	# 今回は「requires_wait」を使わず、ScenarioManagerの自動進行タイマーに委ねる形になるが、
	# もし演出中に次に行かせたくないなら、ここで完了までブロックする。 -> bool:

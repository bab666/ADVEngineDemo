# D:\Works\Godot\ADVEngineDemo\scripts\commands\load_command.gd
extends BaseCommand
class_name LoadCommand

## @load コマンド - ゲームをロード
##
## 書式:
## @load [slot_id]
##
## 例:
## @load          (オートセーブスロット0からロード)
## @load 1        (スロット1からロード)
## @load quick    (クイックセーブスロット-1からロード)

func get_command_name() -> String:
	return "load"

func execute(params: Dictionary, context: Dictionary) -> void:
	var save_manager: SaveManager = context.get("save_manager")
	
	if not save_manager:
		push_error("@load: SaveManagerが見つかりません")
		return
	
	# スロットIDを取得
	var args: String = params.get("args", "")
	var slot_id: int = 0  # デフォルトはオートセーブ
	
	if not args.is_empty():
		if args == "quick":
			slot_id = SaveManager.SLOT_QUICK_SAVE
		elif args.is_valid_int():
			slot_id = args.to_int()
		else:
			push_warning("@load: 無効なスロットID: " + args)
	
	# ロード実行
	var success: bool = save_manager.load_game(slot_id)
	
	if success:
		print("ロード成功: スロット %d" % slot_id)
	else:
		print("ロード失敗: スロット %d" % slot_id)

func requires_wait() -> bool:
	return true  # ロード後はシナリオが再開されるため、この行での処理は終了

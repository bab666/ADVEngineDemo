# D:\Works\Godot\ADVEngineDemo\scripts\commands\save_command.gd
extends BaseCommand
class_name SaveCommand

## @save コマンド - ゲームをセーブ
##
## 書式:
## @save [slot_id]
##
## 例:
## @save          (オートセーブスロット0に保存)
## @save 1        (スロット1に保存)
## @save quick    (クイックセーブスロット-1に保存)

func get_command_name() -> String:
	return "save"

func execute(params: Dictionary, context: Dictionary) -> void:
	var save_manager: SaveManager = context.get("save_manager")
	
	if not save_manager:
		push_error("@save: SaveManagerが見つかりません")
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
			push_warning("@save: 無効なスロットID: " + args)
	
	# セーブ実行
	var success: bool = save_manager.save_game(slot_id)
	
	if success:
		print("セーブ成功: スロット %d" % slot_id)
	else:
		print("セーブ失敗: スロット %d" % slot_id)

func requires_wait() -> bool:
	return false

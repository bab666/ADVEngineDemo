@tool
extends Control

# --- UI参照 ---
# キャラクター選択用
var char_select_button: OptionButton
var refresh_button: Button

# 基本情報
@onready var character_id_input: LineEdit = $HSplitContainer/LeftPanel/VBox/General/CharacterID
@onready var display_name_input: LineEdit = $HSplitContainer/LeftPanel/VBox/General/DisplayName
@onready var description_input: TextEdit = $HSplitContainer/LeftPanel/VBox/General/Description

# 表示設定
@onready var scale_spin: SpinBox = $HSplitContainer/LeftPanel/VBox/Settings/Scale
@onready var mirror_check: CheckBox = $HSplitContainer/LeftPanel/VBox/Settings/Mirror

# プレビュー設定
@onready var bg_select: OptionButton = $HSplitContainer/LeftPanel/VBox/PreviewSettings/BgSelect

# ポートレートリスト
@onready var portraits_list: ItemList = $HSplitContainer/LeftPanel/VBox/Portraits/List
@onready var add_portrait_button: Button = $HSplitContainer/LeftPanel/VBox/Portraits/HBox_Buttons/AddPortraitButton
@onready var save_button: Button = $HSplitContainer/LeftPanel/VBox/Portraits/HBox_Buttons/SaveButton

# 表情編集
@onready var portrait_name_input: LineEdit = $HSplitContainer/LeftPanel/VBox/PortraitEdit/PortraitName
@onready var base_image_button: Button = $HSplitContainer/LeftPanel/VBox/PortraitEdit/BaseImage
@onready var layers_container: VBoxContainer = $HSplitContainer/LeftPanel/VBox/PortraitEdit/Layers

# プレビュー
@onready var preview_viewport: SubViewport = $HSplitContainer/RightPanel/VBox/Preview/SubViewport
@onready var preview_display: Node2D = $HSplitContainer/RightPanel/VBox/Preview/SubViewport/CharacterDisplay
@onready var background_preview: Sprite2D = $HSplitContainer/RightPanel/VBox/Preview/SubViewport/BackgroundPreview
@onready var guide_frame: ReferenceRect = $HSplitContainer/RightPanel/VBox/Preview/SubViewport/GuideFrame
@onready var preview_camera: Camera2D = $HSplitContainer/RightPanel/VBox/Preview/SubViewport/Camera2D

# ズームツールバー
@onready var zoom_in_btn: Button = $HSplitContainer/RightPanel/VBox/ToolBar/ZoomIn
@onready var zoom_out_btn: Button = $HSplitContainer/RightPanel/VBox/ToolBar/ZoomOut
@onready var zoom_reset_btn: Button = $HSplitContainer/RightPanel/VBox/ToolBar/ZoomReset
@onready var zoom_label: Label = $HSplitContainer/RightPanel/VBox/ToolBar/ZoomLabel

# --- 変数 ---
var current_character: CharacterData
var current_portrait_name: String = ""
var file_dialog: FileDialog
var _is_updating_ui: bool = false
var _current_zoom: float = 1.0

const DATA_DIR = "res://resources/characters_data/"
const BG_DIR = "res://resources/backgrounds/"

func _ready():
	_setup_ui()
	_connect_signals()
	
	# 初期化
	current_character = CharacterData.new()
	current_character.character_id = "preview_char"
	
	_refresh_character_list()
	_refresh_background_list()
	
	portraits_list.select_mode = ItemList.SELECT_SINGLE
	print("Character Editor Ready")

func _setup_ui():
	# リスト領域確保
	if portraits_list:
		portraits_list.custom_minimum_size.y = 200
		portraits_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# ファイルダイアログ
	if not file_dialog:
		file_dialog = FileDialog.new()
		file_dialog.access = FileDialog.ACCESS_RESOURCES
		file_dialog.size = Vector2(800, 600)
		add_child(file_dialog)
	
	# キャラクター選択UI構築
	var general_container = $HSplitContainer/LeftPanel/VBox/General
	if general_container.has_node("CharSelectHBox"):
		char_select_button = general_container.get_node("CharSelectHBox/CharSelect")
		refresh_button = general_container.get_node("CharSelectHBox/Refresh")
	else:
		var hbox = HBoxContainer.new()
		hbox.name = "CharSelectHBox"
		var label = Label.new(); label.text = "編集対象:"
		hbox.add_child(label)
		char_select_button = OptionButton.new()
		char_select_button.name = "CharSelect"
		char_select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(char_select_button)
		refresh_button = Button.new(); refresh_button.name = "Refresh"; refresh_button.text = "更新"
		hbox.add_child(refresh_button)
		general_container.add_child(hbox)
		general_container.move_child(hbox, 0)
	
	# シグナル重複防止
	if char_select_button.item_selected.is_connected(_on_character_selected_from_list):
		char_select_button.item_selected.disconnect(_on_character_selected_from_list)
	char_select_button.item_selected.connect(_on_character_selected_from_list)
	
	if refresh_button.pressed.is_connected(_refresh_character_list):
		refresh_button.pressed.disconnect(_refresh_character_list)
	refresh_button.pressed.connect(_refresh_character_list)

func _connect_signals():
	_safe_connect(character_id_input.text_changed, _on_character_id_changed)
	_safe_connect(display_name_input.text_changed, _on_display_name_changed)
	_safe_connect(scale_spin.value_changed, _on_scale_changed)
	_safe_connect(mirror_check.toggled, _on_mirror_toggled)
	
	# 背景選択
	_safe_connect(bg_select.item_selected, _on_background_selected)
	
	_safe_connect(portraits_list.item_selected, _on_portrait_selected)
	_safe_connect(portraits_list.item_clicked, _on_portrait_clicked)
	
	_safe_connect(add_portrait_button.pressed, add_new_portrait)
	_safe_connect(save_button.pressed, save_character)
	
	_safe_connect(portrait_name_input.text_changed, _on_portrait_name_changed)
	_safe_connect(base_image_button.pressed, _on_select_base_image)
	
	# ズーム機能
	_safe_connect(zoom_in_btn.pressed, _on_zoom_in)
	_safe_connect(zoom_out_btn.pressed, _on_zoom_out)
	_safe_connect(zoom_reset_btn.pressed, _on_zoom_reset)

func _safe_connect(signal_obj: Signal, method: Callable):
	if signal_obj.is_connected(method):
		signal_obj.disconnect(method)
	signal_obj.connect(method)

# --- ズーム機能 ---

func _on_zoom_in():
	_current_zoom += 0.1
	_update_zoom()

func _on_zoom_out():
	_current_zoom -= 0.1
	if _current_zoom < 0.1: _current_zoom = 0.1
	_update_zoom()

func _on_zoom_reset():
	_current_zoom = 1.0
	_update_zoom()

func _update_zoom():
	if preview_camera:
		preview_camera.zoom = Vector2(_current_zoom, _current_zoom)
	if zoom_label:
		zoom_label.text = "Zoom: %d%%" % int(_current_zoom * 100)

# --- 背景機能 ---

func _refresh_background_list():
	bg_select.clear()
	bg_select.add_item("背景なし (Gray)", 0)
	bg_select.set_item_metadata(0, "")
	
	var dir = DirAccess.open(BG_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var idx = 1
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpg")):
				bg_select.add_item(file_name, idx)
				bg_select.set_item_metadata(idx, BG_DIR + file_name)
				idx += 1
			file_name = dir.get_next()
	else:
		DirAccess.make_dir_recursive_absolute(BG_DIR)

func _on_background_selected(index: int):
	var bg_path = bg_select.get_item_metadata(index)
	guide_frame.visible = false
	
	if bg_path == "":
		background_preview.texture = null
	else:
		if ResourceLoader.exists(bg_path):
			var tex = load(bg_path)
			background_preview.texture = tex
			# 4Kサイズ以上ならガイド枠を表示
			if tex.get_width() >= 3840 or tex.get_height() >= 2160:
				guide_frame.visible = true
		else:
			push_warning("背景画像が見つかりません: " + bg_path)

# --- キャラクターリスト管理 ---

func _refresh_character_list():
	var old_idx = char_select_button.selected
	char_select_button.clear()
	char_select_button.add_item("➕ 新規作成 (New)", 0)
	char_select_button.set_item_metadata(0, "")
	
	var dir = DirAccess.open(DATA_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var index = 1
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var id = file_name.get_basename()
				char_select_button.add_item("📄 " + id, index)
				char_select_button.set_item_metadata(index, id)
				index += 1
			file_name = dir.get_next()
	else:
		DirAccess.make_dir_recursive_absolute(DATA_DIR)
	
	if old_idx >= 0 and old_idx < char_select_button.item_count:
		char_select_button.selected = old_idx

func _on_character_selected_from_list(index: int):
	var selected_id = char_select_button.get_item_metadata(index)
	if selected_id == "": _reset_editor_for_new()
	else: load_character(selected_id)

func _reset_editor_for_new():
	current_character = CharacterData.new()
	current_character.character_id = "new_character"
	current_portrait_name = ""
	_refresh_ui()

# --- イベントハンドラ ---

func _on_character_id_changed(new_text: String): 
	current_character.character_id = new_text
	_update_preview()

func _on_display_name_changed(new_text: String): current_character.display_name = new_text
func _on_scale_changed(value: float):
	current_character.portrait_scale = value; _update_preview()
func _on_mirror_toggled(toggled: bool):
	current_character.mirror = toggled; _update_preview()

func _on_portrait_clicked(index: int, _at_position: Vector2, _mouse_button_index: int):
	_on_portrait_selected(index)

func _on_portrait_selected(index: int):
	if index < 0: return
	var p_name = portraits_list.get_item_text(index)
	current_portrait_name = p_name
	_load_portrait_to_editor(current_portrait_name)

func _on_portrait_name_changed(new_text: String):
	if _is_updating_ui or current_portrait_name.is_empty(): return
	if current_character.portraits.has(current_portrait_name):
		var data = current_character.portraits[current_portrait_name]
		current_character.portraits.erase(current_portrait_name)
		data.name = new_text
		current_character.portraits[new_text] = data
		current_portrait_name = new_text
		_refresh_portraits_list()
		for i in portraits_list.item_count:
			if portraits_list.get_item_text(i) == new_text:
				portraits_list.select(i); break

func _on_select_base_image():
	_open_file_dialog("*.png, *.jpg ; Images", func(path):
		if current_portrait_name.is_empty(): return
		var p = current_character.portraits.get(current_portrait_name)
		if p: p.base_image = path; base_image_button.text = path.get_file(); _update_preview()
	)

# --- 機能実装 ---

func add_new_portrait():
	var p_name = "portrait_%d" % (current_character.portraits.size() + 1)
	while current_character.portraits.has(p_name): p_name += "_"
	current_character.add_portrait(p_name)
	_refresh_portraits_list()
	for i in portraits_list.item_count:
		if portraits_list.get_item_text(i) == p_name:
			portraits_list.select(i); _on_portrait_selected(i); break

func _refresh_portraits_list():
	portraits_list.clear()
	var keys = current_character.portraits.keys()
	keys.sort()
	for p_name in keys:
		portraits_list.add_item(p_name)

func _load_portrait_to_editor(p_name: String):
	_is_updating_ui = true
	var p = current_character.portraits.get(p_name)
	if not p:
		_is_updating_ui = false; return
	
	portrait_name_input.text = p.name
	base_image_button.text = p.base_image.get_file() if not p.base_image.is_empty() else "Select Base Image..."
	_refresh_layers_ui(p)
	_update_preview()
	_is_updating_ui = false

func _refresh_layers_ui(portrait):
	for child in layers_container.get_children(): child.queue_free()
	
	# データから順序を取得。なければデフォルト
	var order = current_character.parts_order
	if order.is_empty():
		order = ["eyebrows", "eyes", "mouth", "extra"]
		current_character.parts_order = order
	
	for i in range(order.size()):
		var layer_name = order[i]
		var current_path = portrait.layers.get(layer_name, "")
		
		var current_offset = Vector2.ZERO
		if "layer_offsets" in portrait and portrait.layer_offsets.has(layer_name):
			current_offset = portrait.layer_offsets[layer_name]
		
		var hbox = HBoxContainer.new()
		layers_container.add_child(hbox)
		
		# 順序変更ボタン [↑][↓]
		var btn_up = Button.new(); btn_up.text = "↑"
		btn_up.disabled = (i == 0)
		btn_up.pressed.connect(func(): _move_layer_order(i, -1))
		hbox.add_child(btn_up)
		
		var btn_down = Button.new(); btn_down.text = "↓"
		btn_down.disabled = (i == order.size() - 1)
		btn_down.pressed.connect(func(): _move_layer_order(i, 1))
		hbox.add_child(btn_down)
		
		# ラベル
		var label = Label.new()
		label.text = layer_name.capitalize()
		label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(label)
		
		# 画像選択
		var button = Button.new()
		button.text = current_path.get_file() if not current_path.is_empty() else "Select..."
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_select_layer.bind(layer_name))
		hbox.add_child(button)
		
		# 位置調整 (X, Y) - 既存コードと同じ
		var x_spin = SpinBox.new(); x_spin.prefix = "x:"; x_spin.min_value = -1000; x_spin.max_value = 1000; x_spin.step = 1.0
		x_spin.value = current_offset.x; x_spin.custom_minimum_size = Vector2(70, 0)
		x_spin.value_changed.connect(func(val): _on_layer_offset_changed(layer_name, val, true))
		hbox.add_child(x_spin)
		
		var y_spin = SpinBox.new(); y_spin.prefix = "y:"; y_spin.min_value = -1000; y_spin.max_value = 1000; y_spin.step = 1.0
		y_spin.value = current_offset.y; y_spin.custom_minimum_size = Vector2(70, 0)
		y_spin.value_changed.connect(func(val): _on_layer_offset_changed(layer_name, val, false))
		hbox.add_child(y_spin)

# レイヤー順序移動処理
func _move_layer_order(index: int, direction: int):
	var order = current_character.parts_order
	var target_index = index + direction
	
	if target_index >= 0 and target_index < order.size():
		var temp = order[index]
		order[index] = order[target_index]
		order[target_index] = temp
		
		# UI更新
		_load_portrait_to_editor(current_portrait_name)

func _on_select_layer(layer_name: String):
	_open_file_dialog("*.png, *.jpg ; Images", func(path):
		current_character.set_portrait_layer(current_portrait_name, layer_name, path)
		_load_portrait_to_editor(current_portrait_name)
	)

func _on_layer_offset_changed(layer_name: String, value: float, is_x: bool):
	if current_portrait_name.is_empty(): return
	var p = current_character.portraits.get(current_portrait_name)
	if not p: return
	if not "layer_offsets" in p: return
	if p.layer_offsets == null: p.layer_offsets = {}
	
	var offset = p.layer_offsets.get(layer_name, Vector2.ZERO)
	if is_x: offset.x = value
	else: offset.y = value
	p.layer_offsets[layer_name] = offset
	_update_preview()

func _update_preview():
	if current_portrait_name.is_empty(): return
	
	var display_id = current_character.character_id
	if display_id.is_empty():
		display_id = "preview_temp_id"
		current_character.character_id = display_id
	
	preview_display.clear_all()
	preview_display.set_character_data_direct(current_character)
	
	# 4K中央 (1920, 1080) に表示
	preview_display.show_character(display_id, current_portrait_name, 1920, 1080)

func save_character():
	if current_character.character_id.is_empty():
		push_error("Character ID is required"); return
	var save_path = DATA_DIR + "%s.json" % current_character.character_id
	if current_character.save_to_file(save_path):
		print("保存完了: ", save_path)
		EditorInterface.get_resource_filesystem().scan()
		_refresh_character_list()

func load_character(char_id: String):
	var load_path = DATA_DIR + "%s.json" % char_id
	var loaded = CharacterData.load_from_file(load_path)
	if loaded:
		current_character = loaded
		current_portrait_name = ""
		_refresh_ui()
		if portraits_list.item_count > 0:
			portraits_list.select(0)
			_on_portrait_selected(0)
	else:
		push_error("ロード失敗: " + load_path)

func _refresh_ui():
	_is_updating_ui = true
	character_id_input.text = current_character.character_id
	display_name_input.text = current_character.display_name
	scale_spin.value = current_character.portrait_scale
	mirror_check.button_pressed = current_character.mirror
	description_input.text = current_character.description
	_refresh_portraits_list()
	_is_updating_ui = false

func _open_file_dialog(filters: String, callback: Callable):
	if file_dialog.file_selected.is_connected(_on_file_selected_callback):
		file_dialog.file_selected.disconnect(_on_file_selected_callback)
	file_dialog.filters = filters.split(",")
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	var wrapper = func(path): callback.call(path)
	file_dialog.file_selected.connect(wrapper, CONNECT_ONE_SHOT)
	file_dialog.popup_centered()

func _on_file_selected_callback(_path): pass

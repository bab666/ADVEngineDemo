extends Resource
class_name CharacterData

# キャラクター基本情報
@export var character_id: String = ""
@export var display_name: String = ""
@export var nicknames: Array[String] = []
@export var description: String = ""

# デフォルト表示設定
@export var default_portrait: String = "normal"  # デフォルト表情
@export var portrait_scale: float = 1.0
@export var portrait_offset: Vector2 = Vector2.ZERO
@export var mirror: bool = false

# パーツの描画順序 (下から順)
@export var parts_order: Array = ["eyebrows", "eyes", "mouth", "extra"]


# 表情定義（ポートレート名 -> ポートレート設定）
@export var portraits: Dictionary = {}

# 表情の構成要素
class PortraitData:
	var name: String = ""
	var base_image: String = ""  # 基本立ち絵
	var layers: Dictionary = {}  # レイヤー名 -> 画像パス
	var layer_offsets: Dictionary = {} # レイヤー名 -> Vector2 (位置調整用) ※新規追加
	
	func to_dict() -> Dictionary:
		# Vector2はJSON化できないので辞書に変換して保存
		var offsets_dict = {}
		for key in layer_offsets.keys():
			var vec: Vector2 = layer_offsets[key]
			offsets_dict[key] = {"x": vec.x, "y": vec.y}
			
		return {
			"name": name,
			"base_image": base_image,
			"layers": layers,
			"layer_offsets": offsets_dict
		}
	
	static func from_dict(data: Dictionary) -> PortraitData:
		var portrait = PortraitData.new()
		portrait.name = data.get("name", "")
		portrait.base_image = data.get("base_image", "")
		portrait.layers = data.get("layers", {})
		
		# オフセット情報の読み込み（なければ空）
		var offsets_data = data.get("layer_offsets", {})
		for key in offsets_data.keys():
			var vec_data = offsets_data[key]
			portrait.layer_offsets[key] = Vector2(vec_data.get("x", 0), vec_data.get("y", 0))
			
		return portrait

# JSONへの変換
func to_json() -> String:
	var data = {
		"character_id": character_id,
		"display_name": display_name,
		"nicknames": nicknames,
		"description": description,
		"default_portrait": default_portrait,
		"portrait_scale": portrait_scale,
		"portrait_offset": {"x": portrait_offset.x, "y": portrait_offset.y},
		"mirror": mirror,
		"parts_order": parts_order,
		"portraits": {}
	}
	
	for key in portraits.keys():
		var portrait: PortraitData = portraits[key]
		data["portraits"][key] = portrait.to_dict()
	
	return JSON.stringify(data, "\t")

# JSONからの読み込み
static func from_json(json_string: String) -> CharacterData:
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("JSONパースエラー: " + json.get_error_message())
		return null
	
	var data = json.data
	var char_data = CharacterData.new()
	
	char_data.character_id = data.get("character_id", "")
	char_data.display_name = data.get("display_name", "")
	
	# --- 修正箇所: 配列への安全な代入 ---
	var raw_nicknames = data.get("nicknames", [])
	if raw_nicknames is Array:
		char_data.nicknames.assign(raw_nicknames)
	# --------------------------------
	
	char_data.description = data.get("description", "")
	char_data.default_portrait = data.get("default_portrait", "normal")
	char_data.portrait_scale = data.get("portrait_scale", 1.0)
	
	var offset_data = data.get("portrait_offset", {"x": 0, "y": 0})
	char_data.portrait_offset = Vector2(offset_data.x, offset_data.y)
	char_data.mirror = data.get("mirror", false)
	
	var raw_order = data.get("parts_order", [])
	if raw_order is Array and not raw_order.is_empty():
		char_data.parts_order = raw_order

	var portraits_data = data.get("portraits", {})
	for key in portraits_data.keys():
		char_data.portraits[key] = PortraitData.from_dict(portraits_data[key])
	
	return char_data

# ファイルへ保存
func save_to_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ファイルを開けません: " + path)
		return false
	
	file.store_string(to_json())
	file.close()
	return true

# ファイルから読み込み
static func load_from_file(path: String) -> CharacterData:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ファイルを開けません: " + path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	return from_json(json_string)

# 表情を追加
func add_portrait(portrait_name: String, base_image: String = "") -> void:
	var portrait = PortraitData.new()
	portrait.name = portrait_name
	portrait.base_image = base_image
	portraits[portrait_name] = portrait

# 表情のレイヤーを設定
func set_portrait_layer(portrait_name: String, layer_name: String, image_path: String) -> void:
	if not portraits.has(portrait_name):
		add_portrait(portrait_name)
	
	var portrait: PortraitData = portraits[portrait_name]
	portrait.layers[layer_name] = image_path

@tool
extends Node2D
class_name CharacterDisplay

# キャラクター ID -> キャラクターノード
var characters: Dictionary = {}

# キャラクターデータキャッシュ: ID -> CharacterData
var character_data_cache: Dictionary = {}

# エディタ用: 外部から直接CharacterDataを注入
func set_character_data_direct(char_data: CharacterData):
	if char_data:
		character_data_cache[char_data.character_id] = char_data

# キャラクターを表示
func show_character(char_id: String, expression: String, x: int, y: int):
	print("CharacterDisplay: show_character呼び出し id=%s exp=%s" % [char_id, expression])
	
	# キャラクターデータを取得
	var char_data = get_character_data(char_id)
	
	if not char_data:
		push_warning("CharacterDisplay: データが見つかりません ID=" + char_id)
		_show_simple_character(char_id, expression, x, y)
		return
	
	# ノードの準備
	var char_node: Node2D
	if characters.has(char_id):
		char_node = characters[char_id]
	else:
		char_node = Node2D.new()
		char_node.name = char_id
		add_child(char_node)
		characters[char_id] = char_node
	
	# 位置設定
	char_node.position = Vector2(x, y)
	
	# 表情データを取得
	var portrait_data = char_data.portraits.get(expression)
	if not portrait_data:
		push_warning("CharacterDisplay: 表情定義なし exp=" + expression)
		return
	
	# 既存の描画をクリア
	for child in char_node.get_children():
		child.queue_free()
	
	# ベース画像
	if not portrait_data.base_image.is_empty():
		_add_sprite_layer(char_node, portrait_data.base_image, 0)
	
	# レイヤー
	var layer_order = ["eyebrows", "eyes", "mouth", "extra"]
	var current_z = 1
	for layer_name in layer_order:
		if portrait_data.layers.has(layer_name):
			var path = portrait_data.layers[layer_name]
			if not path.is_empty():
				var offset = Vector2.ZERO
				# layer_offsetsが存在する場合のみ取得
				if "layer_offsets" in portrait_data and portrait_data.layer_offsets.has(layer_name):
					offset = portrait_data.layer_offsets[layer_name]
				
				_add_sprite_layer(char_node, path, current_z, offset)
				current_z += 1
	
	# スケール・ミラー
	char_node.scale = Vector2(char_data.portrait_scale, char_data.portrait_scale)
	if char_data.mirror:
		char_node.scale.x *= -1
	
	char_node.show()

# スプライト追加
func _add_sprite_layer(parent: Node2D, path: String, z: int, offset: Vector2 = Vector2.ZERO):
	if not ResourceLoader.exists(path):
		push_warning("画像ファイルなし: " + path)
		return
	
	var sprite = Sprite2D.new()
	sprite.texture = load(path)
	sprite.z_index = z
	sprite.position = offset
	parent.add_child(sprite)

# データ取得
func get_character_data(char_id: String) -> CharacterData:
	if character_data_cache.has(char_id):
		return character_data_cache[char_id]
	
	var path = "res://resources/characters_data/%s.json" % char_id
	if FileAccess.file_exists(path):
		var data = CharacterData.load_from_file(path)
		if data:
			character_data_cache[char_id] = data
			return data
	return null

# 簡易表示（フォールバック）
func _show_simple_character(char_id: String, expression: String, x: int, y: int):
	# 省略（必要なら以前のコードを使用）
	pass

# 全クリア
func clear_all():
	for node in characters.values():
		node.queue_free()
	characters.clear()

@tool
extends Node2D
class_name CharacterDisplay

# キャラクターノード管理
var characters: Dictionary = {}
var character_data_cache: Dictionary = {}

# エディタ用注入メソッド
func set_character_data_direct(char_data: CharacterData):
	if char_data: character_data_cache[char_data.character_id] = char_data

# --- 高機能表示メソッド ---
func show_character_ex(char_id: String, expression: String, params: Dictionary) -> Tween:
	# 1. データ取得
	var char_data = get_character_data(char_id)
	if not char_data:
		push_warning("CharacterDisplay: データなし ID=" + char_id)
		# データがない場合のフォールバック（旧メソッドへ）
		var x = int(params.get("pos", Vector3.ZERO).x)
		var y = int(params.get("pos", Vector3.ZERO).y)
		_show_simple_character(char_id, expression, x, y)
		return null

	# 2. ノード準備
	var char_node: Node2D
	if characters.has(char_id):
		char_node = characters[char_id]
	else:
		char_node = Node2D.new()
		char_node.name = char_id
		add_child(char_node)
		characters[char_id] = char_node
	
	# 3. パラメータのマージ
	var final_scale = params.get("scale") if params.get("scale") != null else char_data.portrait_scale
	var is_mirror = params.get("reflect") if params.has("reflect") else char_data.mirror
	var fade_time = params.get("time", 1000) / 1000.0
	var layer = params.get("layer", 1)
	
	# 位置計算
	var pos_mode = params.get("pos_mode", "manual")
	var pos_vec = params.get("pos", Vector3.ZERO)
	var target_pos = Vector2(pos_vec.x, pos_vec.y)
	
	if pos_mode == "auto":
		# ★修正: 画面サイズから中央を計算
		var viewport_size = get_viewport_rect().size
		# Xは中央、Yは下端(1080など)
		target_pos = Vector2(viewport_size.x / 2, viewport_size.y)
	
	char_node.z_index = layer
	char_node.position = target_pos
	
	# 4. 描画更新
	_update_sprites(char_node, char_data, expression)
	
	# 5. スケール・反転
	var scale_vec = Vector2(final_scale, final_scale)
	if is_mirror: scale_vec.x *= -1
	char_node.scale = scale_vec
	
	# 6. フェードインアニメーション
	char_node.show()
	char_node.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(char_node, "modulate:a", 1.0, fade_time)
	
	return tween

# スプライト構築処理
func _update_sprites(char_node: Node2D, char_data: CharacterData, expression: String):
	for c in char_node.get_children(): c.queue_free()
	
	var portrait = char_data.portraits.get(expression)
	if not portrait: return

	var base_offset = char_data.portrait_offset

	if not portrait.base_image.is_empty():
		_add_sprite(char_node, portrait.base_image, 0, base_offset)
	
	var current_z = 1
	# parts_order対応 (なければデフォルト)
	var order = []
	if "parts_order" in char_data and char_data.parts_order:
		order = char_data.parts_order
	else:
		order = ["eyebrows", "eyes", "mouth", "extra"]
	
	for part_name in order:
		if portrait.layers.has(part_name):
			var path = portrait.layers[part_name]
			if not path.is_empty():
				var part_offset = Vector2.ZERO
				if "layer_offsets" in portrait and portrait.layer_offsets.has(part_name):
					part_offset = portrait.layer_offsets[part_name]
				
				_add_sprite(char_node, path, current_z, base_offset + part_offset)
				current_z += 1

func _add_sprite(parent, path, z, offset):
	if not ResourceLoader.exists(path): return
	var sp = Sprite2D.new()
	sp.texture = load(path)
	sp.z_index = z
	sp.position = offset
	parent.add_child(sp)

# データ取得
func get_character_data(char_id: String) -> CharacterData:
	if character_data_cache.has(char_id): return character_data_cache[char_id]
	var path = "res://resources/characters_data/%s.json" % char_id
	if FileAccess.file_exists(path):
		var d = CharacterData.load_from_file(path)
		if d:
			character_data_cache[char_id] = d
			return d
	return null

# 旧メソッド (互換性維持)
func show_character(char_id: String, expression: String, x: int, y: int):
	var params = {"pos": Vector3(x, y, 0), "time": 0, "pos_mode": "manual"}
	show_character_ex(char_id, expression, params)

func _show_simple_character(char_id: String, expression: String, x: int, y: int):
	# 省略（以前と同じ）
	pass

func hide_character(char_id: String):
	if characters.has(char_id): characters[char_id].hide()

func clear_all():
	for n in characters.values(): n.queue_free()
	characters.clear()

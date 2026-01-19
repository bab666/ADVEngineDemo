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
# コマンドから渡された辞書パラメータ(params)とマージして表示を行う
func show_character_ex(char_id: String, expression: String, params: Dictionary) -> Tween:
	# 1. データ取得
	var char_data = get_character_data(char_id)
	if not char_data:
		push_warning("CharacterDisplay: データなし ID=" + char_id)
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
	
	# 3. パラメータのマージ (デフォルト値 vs 指定値)
	var final_scale = params.get("scale") if params.get("scale") != null else char_data.portrait_scale
	var is_mirror = params.get("reflect") if params.has("reflect") else char_data.mirror
	var fade_time = params.get("time", 1000) / 1000.0 # ms -> sec
	var layer = params.get("layer", 1)
	
	# 位置計算
	var pos_mode = params.get("pos_mode", "manual") # デフォルトはScenarioManager側で制御されるが念のため
	var pos_vec = params.get("pos", Vector3.ZERO)
	var target_pos = Vector2(pos_vec.x, pos_vec.y)
	
	if pos_mode == "auto":
		# ★修正: 画面サイズ動的取得 (Viewportのサイズから計算)
		var viewport_size = get_viewport_rect().size
		# Xは中央、Yは下端 (立ち絵は足元基準と想定)
		target_pos = Vector2(viewport_size.x / 2, viewport_size.y)
		
		# ※もし立ち絵の原点が「画像中央」の場合は、Y位置を調整する必要があります
		# target_pos.y -= 300 # 必要に応じて調整
	
	# Zインデックス (layer)
	char_node.z_index = layer
	
	# 位置適用 (※ここでデータ側の portrait_offset は考慮しない。描画側で足すため)
	char_node.position = target_pos
	
	# 4. 描画更新 (スプライト再生成)
	_update_sprites(char_node, char_data, expression)
	
	# 5. スケール・反転適用
	var scale_vec = Vector2(final_scale, final_scale)
	if is_mirror: scale_vec.x *= -1
	char_node.scale = scale_vec
	
	# 6. アニメーション (フェードイン)
	char_node.show()
	char_node.modulate.a = 0.0 # 透明から開始
	
	var tween = create_tween()
	tween.tween_property(char_node, "modulate:a", 1.0, fade_time)
	
	return tween

# スプライト構築処理
func _update_sprites(char_node: Node2D, char_data: CharacterData, expression: String):
	for c in char_node.get_children(): c.queue_free()
	
	var portrait = char_data.portraits.get(expression)
	if not portrait: return

	# Base位置 (データ側の全体オフセット)
	var base_offset = char_data.portrait_offset

	# Base画像 (常に一番下)
	if not portrait.base_image.is_empty():
		_add_sprite(char_node, portrait.base_image, 0, base_offset)
	
	# パーツ描画 (parts_order の順序に従う)
	var current_z = 1
	var order = char_data.parts_order
	
	# データに順序がない場合のフォールバック
	if order.is_empty(): order = ["eyebrows", "eyes", "mouth", "extra"]
	
	for part_name in order:
		if portrait.layers.has(part_name):
			var path = portrait.layers[part_name]
			if not path.is_empty():
				var part_offset = Vector2.ZERO
				if "layer_offsets" in portrait and portrait.layer_offsets.has(part_name):
					part_offset = portrait.layer_offsets[part_name]
				
				# Baseの位置に乗っかる形で配置
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

# 互換性維持のための古いメソッド
func show_character(char_id: String, expression: String, x: int, y: int):
	# 古い呼び出しを新しい形式に変換
	var params = {"pos": Vector3(x, y, 0), "time": 0}
	show_character_ex(char_id, expression, params)

func hide_character(char_id: String):
	if characters.has(char_id): characters[char_id].hide()

func clear_all():
	for n in characters.values(): n.queue_free()
	characters.clear()

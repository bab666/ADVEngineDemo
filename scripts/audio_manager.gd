extends Node

var bgm_player: AudioStreamPlayer
var se_players: Dictionary = {}  # SE名 -> AudioStreamPlayer

var current_bgm: String = ""
var bgm_volume: float = 0.0  # dB
var se_volume: float = 0.0   # dB

func _ready() -> void:
	# BGMプレイヤー
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

# BGM再生（拡張版）
func play_bgm_ex(file_name: String, params: Dictionary = {}) -> void:
	# デフォルトパラメータ
	var volume = params.get("volume", 100)
	var sprite_time = params.get("sprite_time", "")
	var loop = params.get("loop", true)
	var seek = params.get("seek", 0.0)
	var restart = params.get("restart", false)
	var fade_duration = params.get("fade_duration", 1.0)
	
	# 同じBGMが再生中の場合の処理
	if current_bgm == file_name and bgm_player.playing:
		if not restart:
			return  # 無視
		# restartがtrueなら最初から再生し直し
	
	var audio_path = "res://resources/audio/bgm/%s.ogg" % file_name
	
	if not ResourceLoader.exists(audio_path):
		audio_path = "res://resources/audio/bgm/%s.mp3" % file_name
		if not ResourceLoader.exists(audio_path):
			push_warning("BGMファイルが見つかりません: " + file_name)
			return
	
	# フェードアウト
	if bgm_player.playing and current_bgm != file_name:
		await fade_out_bgm(fade_duration)
	
	# 新しいBGM読み込み
	var stream: AudioStream = load(audio_path)
	
	# sprite_time処理（AudioStreamOggVorbisの場合）
	if sprite_time != "" and stream is AudioStreamOggVorbis:
		var times = sprite_time.split("-")
		if times.size() == 2:
			var start_ms = float(times[0])
			# 修正: 未使用変数の警告を抑制するため _ を付与
			var _end_ms = float(times[1]) 
			
			stream.loop_offset = start_ms / 1000.0
			# 注意: Godotでは終了時刻の指定は直接できないため、
			# ループポイントで代用。完全な実装には別途タイマー処理が必要
	
	bgm_player.stream = stream
	current_bgm = file_name
	
	# ループ設定
	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamMP3:
		stream.loop = loop
	
	# 音量設定（0-100 を dB に変換: -80dB 〜 0dB）
	var target_volume_db = linear_to_db(volume / 100.0)
	set_bgm_volume(target_volume_db)
	
	# シーク位置から再生
	bgm_player.volume_db = -80.0
	bgm_player.play(seek)
	
	# フェードイン
	await fade_in_bgm(fade_duration)

# 簡易版BGM再生（後方互換性）
func play_bgm(file_name: String, fade_duration: float = 1.0) -> void:
	await play_bgm_ex(file_name, {"fade_duration": fade_duration})

# BGM停止
func stop_bgm(fade_duration: float = 0.0) -> void:
	if not bgm_player.playing:
		return
	
	if fade_duration > 0.0:
		await fade_out_bgm(fade_duration)
	
	bgm_player.stop()
	current_bgm = ""

# 特定のBGMを停止（file_nameが現在再生中のものと一致する場合のみ）
func stop_bgm_by_name(file_name: String, fade_duration: float = 0.0) -> void:
	if current_bgm == file_name:
		await stop_bgm(fade_duration)

# フェードイン
func fade_in_bgm(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", bgm_volume, duration)
	await tween.finished

# フェードアウト
func fade_out_bgm(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, duration)
	await tween.finished

# SE再生（拡張版）
func play_se(file_name: String) -> void:
	var audio_path = "res://resources/audio/se/%s.ogg" % file_name
	
	if not ResourceLoader.exists(audio_path):
		audio_path = "res://resources/audio/se/%s.mp3" % file_name
		if not ResourceLoader.exists(audio_path):
			push_warning("SEファイルが見つかりません: " + file_name)
			return
	
	var stream = load(audio_path)
	
	# 新しいAudioStreamPlayerを作成
	var player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = se_volume
	player.stream = stream
	add_child(player)
	
	# SE名で管理
	se_players[file_name] = player
	
	# 再生終了時に自動削除
	player.finished.connect(func():
		if se_players.has(file_name) and se_players[file_name] == player:
			se_players.erase(file_name)
		player.queue_free()
	)
	
	player.play()

# SE停止（全体）
func stop_all_se(fade_duration: float = 0.0) -> void:
	for se_name in se_players.keys():
		await stop_se_by_name(se_name, fade_duration)

# 特定のSEを停止
func stop_se_by_name(file_name: String, fade_duration: float = 0.0) -> void:
	if not se_players.has(file_name):
		return
	
	var player = se_players[file_name]
	
	if fade_duration > 0.0:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_duration)
		await tween.finished
	
	player.stop()
	se_players.erase(file_name)
	player.queue_free()

# 音量設定
func set_bgm_volume(volume: float) -> void:
	bgm_volume = volume
	bgm_player.volume_db = volume

func set_se_volume(volume: float) -> void:
	se_volume = volume
	for player in se_players.values():
		player.volume_db = volume

# dB変換ヘルパー
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

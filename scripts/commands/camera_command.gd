extends BaseCommand
class_name CameraCommand
# ★追加: 待機するかどうかのフラグ
var _should_wait: bool = false

func get_command_name() -> String:
	return "camera"

func get_description() -> String:
	return "カメラを操作します。パラメータ: offset:x,y zoom:z rotation:deg time:ms wait! lazy"

func execute(params: Dictionary, context: Dictionary) -> void:
	var camera = context.get("camera") as Camera2D
	var gm = context.get("game_manager")
	
	if not camera: return
	
	# --- パラメータ取得 ---
	var time_ms = params.get("time", 1000)
	var time_sec = float(time_ms) / 1000.0
	var wait_flag = params.get("wait", true)
	var is_lazy = params.get("lazy", false)
	# ★追加: 今回の実行で待機するかどうかを決定
	_should_wait = wait_flag
	
	# --- 前回の実行状態の処理 (Lazy判定) ---
	var current_tween = context.get("current_tween")
	
	if current_tween and current_tween.is_valid() and current_tween.is_running():
		if not is_lazy:
			# lazyでない場合、前回のターゲット状態へ即座にワープさせる
			if context.has("camera_target_pos"):
				camera.position = context["camera_target_pos"]
			if context.has("camera_target_zoom"):
				camera.zoom = context["camera_target_zoom"]
			if context.has("camera_target_rot"):
				camera.rotation_degrees = context["camera_target_rot"]
		
		# 既存のアニメーションを停止
		current_tween.kill()

	# --- 目標値の決定 ---
	# パラメータに指定があればそれを使い、なければ現在の値（またはLazy処理後の値）を維持
	var viewport_size = camera.get_viewport_rect().size
	var base_pos = viewport_size / 2.0
	
	var target_pos = camera.position
	if params.has("offset"):
		var offset = params.get("offset")
		target_pos = base_pos + offset
	
	var target_zoom = camera.zoom
	if params.has("zoom"):
		var z = params.get("zoom")
		target_zoom = Vector2(z, z)
		
	var target_rot = camera.rotation_degrees
	if params.has("rotation"):
		target_rot = params.get("rotation")
	
	# --- コンテキストに目標値を保存 (次回の lazy=false 用) ---
	context["camera_target_pos"] = target_pos
	context["camera_target_zoom"] = target_zoom
	context["camera_target_rot"] = target_rot
	
	# --- 実行 ---
	# ★修正: 時間が0以下の場合は Tween を作成せず、即時適用する（エラー回避）
	if time_sec <= 0:
		camera.position = target_pos
		camera.zoom = target_zoom
		camera.rotation_degrees = target_rot
		context["current_tween"] = null
		
		# 即時完了の場合の待機処理
		# (0秒待機を入れることで、確実に次のフレームへ進む)
		if _should_wait and not context.get("is_async", false):
			if gm: gm.start_wait(0.0)
			
		print("Camera実行(即時): rotation=%s" % target_rot)
		return

	# 時間がある場合のみ Tween を作成
	var tween = camera.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera, "position", target_pos, time_sec)
	tween.tween_property(camera, "zoom", target_zoom, time_sec)
	tween.tween_property(camera, "rotation_degrees", target_rot, time_sec)
	
	if gm: gm.register_async_task(tween)
	context["current_tween"] = tween
	
	print("Camera実行(Tween): rotation=%s lazy=%s time=%s" % [target_rot, is_lazy, time_ms])
	
	# 待機処理
	if wait_flag:
		if not context.get("is_async", false):
			if gm: gm.start_wait(time_sec)

# ★修正: 実行時に決定したフラグを返す
func requires_wait() -> bool:
	return _should_wait

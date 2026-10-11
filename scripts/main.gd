class_name MainLevel
extends Node2D

@export var endgame_bgm: AudioStream = preload("res://assets/audio/bgm/endgame_scene.wav")

@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _campfire: Campfire = $Environment/CampSite/Campfire
@onready var _forest_trees: Node2D = $Environment/ForestTrees
@onready var _sky_bg: ColorRect = $SkyBackground
@onready var _bg_sky: BackgroundSky = $BackgroundSky
@onready var _hud: CanvasLayer = $HUD
@onready var _end_game_layer: CanvasLayer = $EndGameUI
@onready var _bgm_player: AudioStreamPlayer = $BGMPlayer

var _has_switched_bgm: bool = false


func _ready() -> void:
	if _campfire != null:
		_campfire.wildfire_started.connect(_on_wildfire_started)


## เมื่อกองไฟขยายขนาดใหญ่จนเริ่มลามป่า
func _on_wildfire_started() -> void:
	# 1. ปิดกั้นการควบคุมของผู้เล่นทั้งหมดทันที (Player can't do anything)
	if _player != null:
		_player.disable_input()

	# 2. ปิดและซ่อน HUD ทันทีเมื่อเข้าสู่ฉากจบ (Hide HUD during ending sequence)
	if _hud != null:
		if _hud.has_method("hide_for_ending"):
			_hud.hide_for_ending()
		else:
			_hud.visible = false

	# 3. แพนมุมกล้องขึ้นสู่ท้องฟ้าอย่างช้ามากๆ (Extremely slow majestic pan to sky) โดยให้ภูเขาอยู่กับที่ ไม่ต้องยกขึ้นไปด้วย
	var pan_duration: float = 20.0
	if _camera != null:
		var cam_tween: Tween = create_tween().set_parallel(true)
		cam_tween.tween_property(_camera, "offset:y", -270.0, pan_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		cam_tween.tween_property(_camera, "zoom", Vector2(2.2, 2.2), pan_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 3. ปรับสีท้องฟ้าให้เป็นสีส้มเพลิงลุกโชนอย่างน่าเกรงขาม (โทนสีเดียวกับสไปรต์ท้องฟ้า)
	if _sky_bg != null:
		var tween: Tween = create_tween()
		tween.tween_property(_sky_bg, "color", Color(1.0, 0.231, 0.039, 1.0), 6.0)
	if _bg_sky != null:
		_bg_sky.on_wildfire_started()

	# 4. ไฟลามไปติดต้นไม้ทุกต้นตามลำดับจากซ้ายไปขวา
	if _forest_trees != null:
		var trees: Array[Node] = _forest_trees.get_children()
		for i: int in range(trees.size()):
			var tree_node: ForestTree = trees[i] as ForestTree
			if tree_node != null:
				# ลามทีละต้นห่างกัน 0.6 วินาที
				var delay: float = float(i) * 0.6
				get_tree().create_timer(delay).timeout.connect(tree_node.ignite)

	# 5. ซิงค์จังหวะ BGM (Beat Synchronization): ให้ play_scene เล่นจนจบลูปเดิมก่อน แล้วจึงสลับเป็น endgame_scene ทันที
	var time_until_loop_end: float = _calculate_remaining_loop_time()
	if time_until_loop_end <= 0.05:
		_switch_to_endgame_bgm()
	else:
		get_tree().create_timer(time_until_loop_end).timeout.connect(_switch_to_endgame_bgm)

	# 6. แสดงหน้าจอ End Game สรุปผลอย่างนุ่มนวลหลังจากมุมกล้องและเพลงเข้าสู่จุดไคลแมกซ์
	var ui_delay: float = maxf(pan_duration + 0.8, time_until_loop_end + 0.8)
	get_tree().create_timer(ui_delay).timeout.connect(_show_end_game_screen)


## คำนวณเวลาที่เหลือจนกว่าจะจบลูปของ play_scene.wav ปัจจุบัน
func _calculate_remaining_loop_time() -> float:
	if _bgm_player == null or _bgm_player.stream == null or not _bgm_player.playing:
		return 0.0

	var loop_length: float = _bgm_player.stream.get_length()
	var current_pos: float = _bgm_player.get_playback_position()
	var remaining: float = loop_length - current_pos

	return maxf(0.02, remaining)


## สลับเพลงพื้นหลังเป็น endgame_scene.wav ตรงจังหวะลูป
func _switch_to_endgame_bgm() -> void:
	if _has_switched_bgm:
		return
	_has_switched_bgm = true

	if _bgm_player != null and endgame_bgm != null:
		if endgame_bgm is AudioStreamWAV:
			(endgame_bgm as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_bgm_player.stream = endgame_bgm
		_bgm_player.play(0.0)


func _show_end_game_screen() -> void:
	if _hud != null:
		_hud.visible = false
	if _end_game_layer != null:
		_end_game_layer.visible = true
		var overlay: Control = _end_game_layer.get_node_or_null("Overlay") as Control
		var center_box: Control = _end_game_layer.get_node_or_null("CenterBox") as Control
		if overlay != null:
			overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var t1: Tween = create_tween()
			t1.tween_property(overlay, "modulate:a", 1.0, 1.2)
		if center_box != null:
			center_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var t2: Tween = create_tween()
			t2.tween_property(center_box, "modulate:a", 1.0, 1.5)

class_name HUD
extends CanvasLayer

const ICON_HANDS: Texture2D = preload("res://assets/ui/icons/icon_hands.png")
const ICON_BROOM: Texture2D = preload("res://assets/ui/icons/icon_broom.png")
const ICON_BLOWER: Texture2D = preload("res://assets/ui/icons/icon_blower.png")
const ICON_COIN: Texture2D = preload("res://assets/ui/icons/icon_coin.png")
const ICON_LEAF: Texture2D = preload("res://assets/ui/icons/icon_leaf.png")

const KEY_E: Texture2D = preload("res://assets/ui/keys/key_e.png")
const KEY_SPACE: Texture2D = preload("res://assets/ui/keys/key_space.png")

@onready var _leaf_label: Label = %LeafLabel
@onready var _coin_label: Label = %CoinLabel

@onready var _tool_label: Label = %ToolLabel
@onready var _tool_icon: TextureRect = %ToolIcon

@onready var _prompt_box: PanelContainer = %PromptBox
@onready var _prompt_key: TextureRect = %PromptKey
@onready var _prompt_label: Label = %PromptLabel

@onready var _tent_upgrade_alert: PanelContainer = %TentUpgradeAlert
@onready var _tent_alert_label: Label = %TentAlertLabel

var _player: Player = null
var _tent: Tent = null
var _alert_tween: Tween = null
var _alert_pulse_tween: Tween = null


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player != null:
		_player.coins_changed.connect(_on_coins_changed)
		_player.leaves_changed.connect(_on_leaves_changed)
		_player.tool_changed.connect(_on_tool_changed)
		if _player.has_signal("prompt_updated"):
			_player.connect("prompt_updated", _on_prompt_updated)

		# สถานะเริ่มต้น
		_on_coins_changed(_player.coins)
		_on_leaves_changed(_player.carried_leaves, _player.max_hand_capacity)
		_on_tool_changed(_player.current_tool)

	_tent = _get_tent()
	_check_tent_upgrade_alert()

	if _prompt_box != null:
		_prompt_box.visible = false


func _get_tent() -> Tent:
	if _tent == null:
		_tent = get_tree().get_first_node_in_group("tent") as Tent
		if _tent != null and not _tent.upgrade_purchased.is_connected(_on_tent_upgrade_purchased):
			_tent.upgrade_purchased.connect(_on_tent_upgrade_purchased)
	return _tent


func _on_tent_upgrade_purchased(_step: int, _title: String, _cost: int) -> void:
	_check_tent_upgrade_alert()


## ตรวจสอบสถานะการอัพเกรดเต็นท์และแสดง/ซ่อน Alert ที่กึ่งกลางบนของหน้าจอ
func _check_tent_upgrade_alert() -> void:
	if _tent_upgrade_alert == null:
		return

	var tent: Tent = _get_tent()
	if tent == null or _player == null:
		_set_alert_visible(false)
		return

	# หากอัพเกรดครบทุกขั้นแล้ว ให้ซ่อน Alert
	if _player.upgrade_step >= tent.get_total_steps():
		_set_alert_visible(false)
		return

	var info: Dictionary = tent.get_upgrade_info(_player.upgrade_step)
	if not info.get("valid", false):
		_set_alert_visible(false)
		return

	var cost: int = int(info.get("cost", 999999))
	var can_afford: bool = _player.coins >= cost

	_set_alert_visible(can_afford)


func _set_alert_visible(should_show: bool) -> void:
	if _tent_upgrade_alert == null:
		return

	if should_show:
		if _tent_alert_label != null:
			_tent_alert_label.text = "Tent Upgrade Available!"
		if not _tent_upgrade_alert.visible:
			_tent_upgrade_alert.visible = true
			_play_alert_appear_animation()
	else:
		if _tent_upgrade_alert.visible:
			if _alert_pulse_tween != null and _alert_pulse_tween.is_valid():
				_alert_pulse_tween.kill()
			if _alert_tween != null and _alert_tween.is_valid():
				_alert_tween.kill()
			_tent_upgrade_alert.visible = false
			_tent_upgrade_alert.modulate.a = 1.0


func _play_alert_appear_animation() -> void:
	if _tent_upgrade_alert == null:
		return
	if _alert_tween != null and _alert_tween.is_valid():
		_alert_tween.kill()
	if _alert_pulse_tween != null and _alert_pulse_tween.is_valid():
		_alert_pulse_tween.kill()

	_tent_upgrade_alert.pivot_offset = _tent_upgrade_alert.size / 2.0
	_tent_upgrade_alert.scale = Vector2(0.85, 0.85)
	_tent_upgrade_alert.modulate.a = 0.0

	_alert_tween = create_tween().set_parallel(true)
	_alert_tween.tween_property(_tent_upgrade_alert, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_alert_tween.tween_property(_tent_upgrade_alert, "modulate:a", 1.0, 0.15)
	_alert_tween.chain().tween_callback(_start_alert_pulse)


func _start_alert_pulse() -> void:
	if _tent_upgrade_alert == null or not _tent_upgrade_alert.visible:
		return
	if _alert_pulse_tween != null and _alert_pulse_tween.is_valid():
		_alert_pulse_tween.kill()

	_alert_pulse_tween = create_tween().set_loops()
	_alert_pulse_tween.tween_property(_tent_upgrade_alert, "modulate:a", 0.75, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_alert_pulse_tween.tween_property(_tent_upgrade_alert, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_coins_changed(new_amount: int) -> void:
	if _coin_label != null:
		_coin_label.text = "%d" % new_amount
		# แอนิเมชันเด้งเล็กน้อยเมื่อจำนวนเงินเปลี่ยน
		var tween: Tween = create_tween()
		tween.tween_property(_coin_label, "scale", Vector2(1.2, 1.2), 0.08)
		tween.tween_property(_coin_label, "scale", Vector2.ONE, 0.12)

	_check_tent_upgrade_alert()


func _on_leaves_changed(current: int, _maximum: int) -> void:
	if _leaf_label != null:
		_leaf_label.text = "%d" % current


func _on_tool_changed(new_tool: Player.ToolType) -> void:
	if _player == null:
		return

	match new_tool:
		Player.ToolType.HANDS:
			if _tool_icon != null: _tool_icon.texture = ICON_HANDS
			if _tool_label != null:
				_tool_label.text = "Hands" if _player.hands_level <= 1 else "Hands Lv.%d" % _player.hands_level
		Player.ToolType.BROOM:
			if _tool_icon != null: _tool_icon.texture = ICON_BROOM
			if _tool_label != null:
				_tool_label.text = "Broom" if _player.broom_level <= 1 else "Broom Lv.%d" % _player.broom_level
		Player.ToolType.BLOWER:
			if _tool_icon != null: _tool_icon.texture = ICON_BLOWER
			if _tool_label != null:
				_tool_label.text = "Blower" if _player.blower_level <= 1 else "Blower Lv.%d" % _player.blower_level


func _on_prompt_updated(key_code: String, text: String, should_show: bool) -> void:
	if _prompt_box == null:
		return

	if not should_show or text.is_empty():
		_prompt_box.visible = false
		return

	_prompt_box.visible = true
	if _prompt_label != null:
		_prompt_label.text = text

	if _prompt_key != null:
		match key_code.to_lower():
			"e":
				_prompt_key.texture = KEY_E
				_prompt_key.custom_minimum_size = Vector2(28, 28)
				_prompt_key.visible = true
			"space":
				_prompt_key.texture = KEY_SPACE
				_prompt_key.custom_minimum_size = Vector2(56, 28)
				_prompt_key.visible = true
			_:
				_prompt_key.visible = false

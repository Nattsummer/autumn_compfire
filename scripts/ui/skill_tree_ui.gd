class_name SkillTreeUI
extends CanvasLayer

signal closed()
signal upgrade_completed(step: int, title: String)

var _player: Player = null
var _tent: Tent = null
var _selected_index: int = 0

## โหนดอ้างอิงใน Scene
@onready var _root_control: Control = $RootControl
@onready var _coins_label: Label = $RootControl/Margin/VBox/TopBar/CoinsLabel
@onready var _back_button: Button = $RootControl/Margin/VBox/TopBar/BackButton
@onready var _rail_hbox: HBoxContainer = $RootControl/Margin/VBox/TrackArea/RailHBox

@onready var _card_title: Label = $RootControl/Margin/VBox/DetailContainer/DetailCard/CardMargin/CardVBox/CardHeaderHBox/CardTitle
@onready var _card_status: Label = $RootControl/Margin/VBox/DetailContainer/DetailCard/CardMargin/CardVBox/CardHeaderHBox/CardStatus
@onready var _card_desc: Label = $RootControl/Margin/VBox/DetailContainer/DetailCard/CardMargin/CardVBox/CardDesc
@onready var _card_stats: Label = $RootControl/Margin/VBox/DetailContainer/DetailCard/CardMargin/CardVBox/CardStats
@onready var _action_button: Button = $RootControl/Margin/VBox/DetailContainer/DetailCard/CardMargin/CardVBox/ActionHBox/ActionButton


func _ready() -> void:
	visible = false
	if _back_button != null:
		_back_button.pressed.connect(close)
	if _action_button != null:
		_action_button.pressed.connect(_on_action_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# นำทางซ้าย-ขวาบนเส้น Progression Rail ด้วย A/D หรือ ลูกศร
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_change_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_change_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		# หากกำลังโฟกัสอยู่ที่โหนดปัจจุบันที่พร้อมอัพเกรด ให้กดอัพเกรดทันที
		if _can_purchase_selected():
			_execute_upgrade_selected()
		else:
			close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		close()
		get_viewport().set_input_as_handled()


## เปิดหน้าต่าง Skill Tree
func open(player: Player, tent: Tent) -> void:
	_player = player
	_tent = tent
	# เริ่มต้นโฟกัสที่โหนดปัจจุบันที่พร้อมอัพเกรด (หรือโหนดสุดท้ายหากอัพเต็มแล้ว)
	_selected_index = clampi(_player.upgrade_step + 1, 0, 8)
	visible = true
	refresh()


## ปิดหน้าต่าง
func close() -> void:
	visible = false
	closed.emit()


## สลับการเลือกโหนดซ้ายขวา
func _change_selection(delta: int) -> void:
	_selected_index = clampi(_selected_index + delta, 0, 8)
	refresh()


## รายการข้อมูล 9 โหนดบนรางแนวนอน
func _get_all_nodes_data() -> Array[Dictionary]:
	return [
		{
			"tool_name": "HANDS",
			"tier": "TIER I",
			"numeral": "I",
			"is_starter": true,
			"step": -1,
			"title": "Basic Hands",
			"desc": "Starter equipment. Gather single leaves by hand.",
			"stats": "Carrying Capacity: %d Leaves" % _tent.hands_capacities[0],
			"cost": 0
		},
		{
			"tool_name": "HANDS",
			"tier": "TIER II",
			"numeral": "II",
			"is_starter": false,
			"step": 0,
			"title": "Deep Pockets",
			"desc": "Reinforced coat pockets allow gathering multiple leaves.",
			"stats": "Capacity: %d  →  %d Leaves (+%d)" % [_tent.hands_capacities[0], _tent.hands_capacities[1], _tent.hands_capacities[1] - _tent.hands_capacities[0]],
			"cost": _tent.upgrade_costs[0]
		},
		{
			"tool_name": "HANDS",
			"tier": "TIER III",
			"numeral": "III",
			"is_starter": false,
			"step": 1,
			"title": "Canvas Leaf Sack",
			"desc": "Maximum handheld capacity for efficient campfire feeding.",
			"stats": "Capacity: %d  →  %d Leaves (Max)" % [_tent.hands_capacities[1], _tent.hands_capacities[2]],
			"cost": _tent.upgrade_costs[1]
		},
		{
			"tool_name": "BROOM",
			"tier": "TIER I",
			"numeral": "I",
			"is_starter": false,
			"step": 2,
			"title": "Bamboo Forest Broom",
			"desc": "Unlocks Broom tool. Sweeps leaf piles across the ground into piles or fire.",
			"stats": "Unlock Broom  •  Sweep: %.0f Leaves  •  Cooldown: %.2fs" % [_tent.broom_sweeps[0], _tent.broom_cooldowns[0]],
			"cost": _tent.upgrade_costs[2]
		},
		{
			"tool_name": "BROOM",
			"tier": "TIER II",
			"numeral": "II",
			"is_starter": false,
			"step": 3,
			"title": "Wide Bristles",
			"desc": "Wider broom head and lighter shaft for faster sweeping.",
			"stats": "Sweep: %.0f → %.0f  •  Cooldown: %.2fs → %.2fs" % [_tent.broom_sweeps[0], _tent.broom_sweeps[1], _tent.broom_cooldowns[0], _tent.broom_cooldowns[1]],
			"cost": _tent.upgrade_costs[3]
		},
		{
			"tool_name": "BROOM",
			"tier": "TIER III",
			"numeral": "III",
			"is_starter": false,
			"step": 4,
			"title": "Master Sweeper",
			"desc": "Pinnacle sweeping technique. Moves massive leaf piles with rapid recovery.",
			"stats": "Sweep: %.0f → %.0f  •  Cooldown: %.2fs → %.2fs (Max)" % [_tent.broom_sweeps[1], _tent.broom_sweeps[2], _tent.broom_cooldowns[1], _tent.broom_cooldowns[2]],
			"cost": _tent.upgrade_costs[4]
		},
		{
			"tool_name": "BLOWER",
			"tier": "TIER I",
			"numeral": "I",
			"is_starter": false,
			"step": 5,
			"title": "Portable Leaf Blower",
			"desc": "Unlocks Blower tool. Hold interact to continuously blow and feed leaves.",
			"stats": "Unlock Blower  •  Continuous Flow: %.0f Leaves / sec" % _tent.blower_rates[0],
			"cost": _tent.upgrade_costs[5]
		},
		{
			"tool_name": "BLOWER",
			"tier": "TIER II",
			"numeral": "II",
			"is_starter": false,
			"step": 6,
			"title": "Turbo Air Intake",
			"desc": "Enhanced turbine power pushes larger swarms of leaves into the flames.",
			"stats": "Blow Rate: %.0f  →  %.0f Leaves / sec" % [_tent.blower_rates[0], _tent.blower_rates[1]],
			"cost": _tent.upgrade_costs[6]
		},
		{
			"tool_name": "BLOWER",
			"tier": "TIER III",
			"numeral": "III",
			"is_starter": false,
			"step": 7,
			"title": "Hurricane Vortex",
			"desc": "Maximum output blower. Pours hundreds of leaves into the fire for catastrophic endgame heat.",
			"stats": "Blow Rate: %.0f  →  %.0f Leaves / sec (Max Climax)" % [_tent.blower_rates[1], _tent.blower_rates[2]],
			"cost": _tent.upgrade_costs[7]
		}
	]


## อัปเดตการแสดงผลทั้งหมด
func refresh() -> void:
	if _player == null or _tent == null:
		return

	if _coins_label != null:
		_coins_label.text = "COINS: %d" % _player.coins

	var nodes_data: Array[Dictionary] = _get_all_nodes_data()
	_rebuild_rail(nodes_data)
	_update_detail_card(nodes_data[_selected_index])


## สร้างเส้นและโหนดบนรางแนวนอน
func _rebuild_rail(nodes_data: Array[Dictionary]) -> void:
	if _rail_hbox == null:
		return

	for child: Node in _rail_hbox.get_children():
		child.queue_free()

	for i: int in range(nodes_data.size()):
		var data: Dictionary = nodes_data[i]
		var is_starter: bool = bool(data["is_starter"])
		var step: int = int(data["step"])
		var is_owned: bool = is_starter or (step >= 0 and _player.upgrade_step > step)
		var is_current_target: bool = not is_starter and (_player.upgrade_step == step)
		var is_selected: bool = (i == _selected_index)

		# วาดปุ่มโหนด
		var node_btn: Button = Button.new()
		node_btn.custom_minimum_size = Vector2(48, 48)

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

		node_btn.text = String(data["numeral"])
		node_btn.add_theme_font_size_override("font_size", 13)

		if is_selected:
			# โหนดที่กำลังเลือกดูอยู่
			style.border_color = Color(1.0, 0.85, 0.45, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3

		if is_owned:
			style.bg_color = Color(0.16, 0.26, 0.18, 0.95)
			if not is_selected:
				style.border_color = Color(0.38, 0.65, 0.42, 0.9)
			node_btn.add_theme_color_override("font_color", Color(0.65, 0.92, 0.7, 1.0))
		elif is_current_target:
			style.bg_color = Color(0.28, 0.18, 0.10, 0.95)
			if not is_selected:
				style.border_color = Color(0.95, 0.60, 0.25, 0.9)
			node_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
		else:
			style.bg_color = Color(0.08, 0.08, 0.10, 0.7)
			if not is_selected:
				style.border_color = Color(0.20, 0.22, 0.26, 0.6)
			node_btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 0.8))

		node_btn.add_theme_stylebox_override("normal", style)
		node_btn.add_theme_stylebox_override("hover", style)
		node_btn.add_theme_stylebox_override("pressed", style)

		var target_idx: int = i
		node_btn.pressed.connect(func() -> void:
			_selected_index = target_idx
			refresh()
		)

		_rail_hbox.add_child(node_btn)

		# วาดเส้นเชื่อมต่อไปยังโหนดถัดไป
		if i < nodes_data.size() - 1:
			var next_data: Dictionary = nodes_data[i + 1]
			var next_step: int = int(next_data["step"])
			var next_owned: bool = (_player.upgrade_step > next_step)

			var line_panel: Panel = Panel.new()
			line_panel.custom_minimum_size = Vector2(40, 4)
			line_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			var line_style: StyleBoxFlat = StyleBoxFlat.new()
			if is_owned and next_owned:
				line_style.bg_color = Color(0.38, 0.65, 0.42, 0.8)
			elif is_owned and is_current_target:
				line_style.bg_color = Color(0.95, 0.60, 0.25, 0.7)
			else:
				line_style.bg_color = Color(0.18, 0.20, 0.24, 0.5)

			line_panel.add_theme_stylebox_override("panel", line_style)
			_rail_hbox.add_child(line_panel)


## อัปเดตรายละเอียดการ์ดด้านล่าง
func _update_detail_card(data: Dictionary) -> void:
	if _card_title == null:
		return

	var is_starter: bool = bool(data["is_starter"])
	var step: int = int(data["step"])
	var cost: int = int(data["cost"])
	var is_owned: bool = is_starter or (step >= 0 and _player.upgrade_step > step)
	var is_current_target: bool = not is_starter and (_player.upgrade_step == step)

	_card_title.text = "%s — %s : %s" % [String(data["tool_name"]), String(data["tier"]), String(data["title"])]
	_card_desc.text = String(data["desc"])
	_card_stats.text = String(data["stats"])

	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4

	if is_owned:
		_card_status.text = "ACQUIRED"
		_card_status.add_theme_color_override("font_color", Color(0.4, 0.85, 0.45, 1.0))
		_action_button.text = "✓ COMPLETED"
		_action_button.disabled = true
		btn_style.bg_color = Color(0.14, 0.20, 0.16, 0.8)
		_action_button.add_theme_stylebox_override("disabled", btn_style)

	elif is_current_target:
		_card_status.text = "READY TO UPGRADE"
		_card_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35, 1.0))

		if _player.coins >= cost:
			_action_button.text = "[ E ] UPGRADE — %d COINS" % cost
			_action_button.disabled = false
			btn_style.bg_color = Color(0.85, 0.50, 0.18, 1.0)
			_action_button.add_theme_stylebox_override("normal", btn_style)
		else:
			_action_button.text = "REQUIRES %d COINS (HAVE %d)" % [cost, _player.coins]
			_action_button.disabled = true
			btn_style.bg_color = Color(0.24, 0.18, 0.16, 0.8)
			_action_button.add_theme_stylebox_override("disabled", btn_style)

	else:
		_card_status.text = "LOCKED"
		_card_status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
		_action_button.text = "LOCKED — COMPLETE PREVIOUS TIER FIRST"
		_action_button.disabled = true
		btn_style.bg_color = Color(0.12, 0.12, 0.14, 0.6)
		_action_button.add_theme_stylebox_override("disabled", btn_style)


func _can_purchase_selected() -> bool:
	if _player == null or _tent == null:
		return false
	var nodes_data: Array[Dictionary] = _get_all_nodes_data()
	var data: Dictionary = nodes_data[_selected_index]
	var step: int = int(data["step"])
	if step != _player.upgrade_step:
		return false
	var cost: int = int(data["cost"])
	return _player.coins >= cost


func _on_action_button_pressed() -> void:
	if _can_purchase_selected():
		_execute_upgrade_selected()


func _execute_upgrade_selected() -> void:
	var nodes_data: Array[Dictionary] = _get_all_nodes_data()
	var data: Dictionary = nodes_data[_selected_index]
	var step: int = int(data["step"])
	var cost: int = int(data["cost"])

	_player.coins -= cost
	_player.coins_changed.emit(_player.coins)
	_player.apply_upgrade_step(step)
	_player.upgrade_step += 1

	_tent.upgrade_purchased.emit(step, String(data["title"]), cost)
	_tent.update_label_display(_player.upgrade_step, _player.coins)
	upgrade_completed.emit(step, String(data["title"]))

	# ขยับโฟกัสไปยังโหนดถัดไปอัตโนมัติ
	_selected_index = clampi(_player.upgrade_step + 1, 0, 8)
	refresh()

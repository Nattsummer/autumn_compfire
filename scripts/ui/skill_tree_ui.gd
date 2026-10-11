class_name SkillTreeUI
extends CanvasLayer

signal closed()
signal upgrade_completed(step: int, title: String)

const ICON_HANDS: Texture2D = preload("res://assets/ui/icons/icon_hands.png")
const ICON_BROOM: Texture2D = preload("res://assets/ui/icons/icon_broom.png")
const ICON_BLOWER: Texture2D = preload("res://assets/ui/icons/icon_blower.png")
const ICON_COIN: Texture2D = preload("res://assets/ui/icons/icon_coin.png")
const FONT_PEABERRY: FontFile = preload("res://assets/font/Peaberry-Font-v2.0/Peaberry Font Family/Peaberry Base/Peaberry-Base.otf")

var _player: Player = null
var _tent: Tent = null
var _selected_index: int = 0
var _is_closing: bool = false
var _open_tween: Tween = null
var _close_tween: Tween = null

## โหนดอ้างอิงใน Scene (Unique Names)
@onready var _backdrop: ColorRect = %Backdrop
@onready var _top_section: Control = %TopSection
@onready var _middle_section: Control = %MiddleSection
@onready var _bottom_section: Control = %BottomSection

@onready var _coins_label: Label = %CoinsLabel
@onready var _back_button: Button = %BackButton
@onready var _rail_hbox: HBoxContainer = %RailHBox

@onready var _detail_icon: TextureRect = %DetailIcon
@onready var _detail_tier: Label = %DetailTier
@onready var _card_title: Label = %CardTitle
@onready var _card_status: Label = %CardStatus
@onready var _card_desc: Label = %CardDesc
@onready var _card_stats: Label = %CardStats
@onready var _action_button: Button = %ActionButton


func _ready() -> void:
	visible = false
	if _back_button != null:
		_back_button.pressed.connect(close)
	if _action_button != null:
		_action_button.pressed.connect(_on_action_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_closing:
		return

	# นำทางซ้าย-ขวาบนเส้น Progression Rail ด้วย A/D หรือ ลูกศร
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_change_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_change_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if _can_purchase_selected():
			_execute_upgrade_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		close()
		get_viewport().set_input_as_handled()


## เปิดหน้าต่าง Skill Tree พร้อมเล่นแอนิเมชันเปิด 2 จังหวะ
func open(player: Player, tent: Tent) -> void:
	_player = player
	_tent = tent
	_is_closing = false
	_set_hud_visible(false)
	# เริ่มต้นโฟกัสที่โหนดปัจจุบันที่พร้อมอัพเกรด (หรือโหนดสุดท้ายหากอัพเต็มแล้ว)
	_selected_index = clampi(_player.upgrade_step + 1, 0, 8)
	visible = true
	refresh()
	_play_open_animation()


## ปิดหน้าต่างพร้อมเล่นแอนิเมชันปิด
func close() -> void:
	if _is_closing:
		return
	_play_close_animation()


## เล่นแอนิเมชันเปิด: 1. Slide Top/Bottom เข้ามา -> 2. Popup Middle Nodes
func _play_open_animation() -> void:
	if _close_tween != null and _close_tween.is_valid():
		_close_tween.kill()
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()

	var viewport_h: float = get_viewport().get_visible_rect().size.y
	var resting_bottom_y: float = maxf(0.0, viewport_h - 236.0)

	# 1. ตั้งค่าเริ่มต้นสำหรับ Phase 1: Slide
	if _backdrop != null:
		_backdrop.modulate.a = 0.0

	if _top_section != null:
		_top_section.position.y = -85.0
		_top_section.modulate.a = 0.0

	if _bottom_section != null:
		_bottom_section.position.y = resting_bottom_y + 240.0
		_bottom_section.modulate.a = 0.0

	# 2. ตั้งค่าเริ่มต้นสำหรับ Phase 2: Popup Middle Nodes
	if _middle_section != null:
		_middle_section.pivot_offset = Vector2.ZERO
		_middle_section.scale = Vector2.ZERO
		_middle_section.modulate.a = 0.0

	_open_tween = create_tween().set_parallel(true)

	# --- Phase 1: Slide In ---
	if _backdrop != null:
		_open_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.20)

	if _top_section != null:
		_open_tween.tween_property(_top_section, "position:y", 0.0, 0.24)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(_top_section, "modulate:a", 1.0, 0.18)

	if _bottom_section != null:
		_open_tween.tween_property(_bottom_section, "position:y", resting_bottom_y, 0.24)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(_bottom_section, "modulate:a", 1.0, 0.18)

	# --- Phase 2: Popup Middle Nodes (หน่วงเวลา 0.10s ให้จังหวะต่อกันอย่างลื่นไหล) ---
	if _middle_section != null:
		_open_tween.tween_property(_middle_section, "scale", Vector2.ONE, 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.10)
		_open_tween.tween_property(_middle_section, "modulate:a", 1.0, 0.14).set_delay(0.10)


## เล่นแอนิเมชันปิด: หด Middle Nodes แล้วสไลด์ Top/Bottom ออก
func _play_close_animation() -> void:
	if _is_closing:
		return
	_is_closing = true

	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _close_tween != null and _close_tween.is_valid():
		_close_tween.kill()

	var viewport_h: float = get_viewport().get_visible_rect().size.y
	var resting_bottom_y: float = maxf(0.0, viewport_h - 236.0)

	_close_tween = create_tween().set_parallel(true)

	# หดและเฟด Middle nodes ออก
	if _middle_section != null:
		_close_tween.tween_property(_middle_section, "scale", Vector2(0.6, 0.6), 0.12)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_close_tween.tween_property(_middle_section, "modulate:a", 0.0, 0.10)

	# สไลด์ Top ขึ้น และ Bottom ลง
	if _top_section != null:
		_close_tween.tween_property(_top_section, "position:y", -85.0, 0.15)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_close_tween.tween_property(_top_section, "modulate:a", 0.0, 0.12)

	if _bottom_section != null:
		_close_tween.tween_property(_bottom_section, "position:y", resting_bottom_y + 240.0, 0.15)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_close_tween.tween_property(_bottom_section, "modulate:a", 0.0, 0.12)

	if _backdrop != null:
		_close_tween.tween_property(_backdrop, "modulate:a", 0.0, 0.15)

	# เมื่อเสร็จสิ้น ให้ซ่อนและคืนค่า HUD
	_close_tween.chain().tween_callback(func() -> void:
		visible = false
		_set_hud_visible(true)
		_is_closing = false
		closed.emit()
	)


func _set_hud_visible(should_show: bool) -> void:
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud") as CanvasLayer
	if hud == null:
		hud = get_tree().root.find_child("HUD", true, false) as CanvasLayer
	if hud != null:
		hud.visible = should_show


## สลับการเลือกโหนดซ้ายขวา
func _change_selection(delta: int) -> void:
	_selected_index = clampi(_selected_index + delta, 0, 8)
	refresh()


## ดึง Texture ไอคอนของเครื่องมือ
func _get_tool_icon(tool_name: String) -> Texture2D:
	match tool_name:
		"HANDS":
			return ICON_HANDS
		"BROOM":
			return ICON_BROOM
		"BLOWER":
			return ICON_BLOWER
		_:
			return ICON_HANDS


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
			"desc": "Starter camp equipment. Gather fallen leaves one by one by hand.",
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
			"desc": "Reinforced coat pockets allow gathering multiple leaves into bundles.",
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
			"desc": "Heavy-duty canvas sack for high capacity leaf collection.",
			"stats": "Capacity: %d  →  %d Leaves (Max Handheld)" % [_tent.hands_capacities[1], _tent.hands_capacities[2]],
			"cost": _tent.upgrade_costs[1]
		},
		{
			"tool_name": "BROOM",
			"tier": "TIER I",
			"numeral": "I",
			"is_starter": false,
			"step": 2,
			"title": "Bamboo Forest Broom",
			"desc": "Unlocks Broom tool. Sweeps leaves in sweeping arcs directly toward the fire.",
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
			"desc": "Sturdier wide-bristle head gathers larger piles with rapid recovery.",
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
			"desc": "Handcrafted balance for sweeping immense piles in an instant.",
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
			"desc": "Unlocks Blower tool. Hold interact to blast a continuous stream of leaves.",
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
			"desc": "Reinforced turbine channels gusts of wind into blazing campfire embers.",
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
			"desc": "Pinnacle engineering. Pours hundreds of dry leaves into the flames for endgame inferno heat.",
			"stats": "Blow Rate: %.0f  →  %.0f Leaves / sec (Max Inferno)" % [_tent.blower_rates[1], _tent.blower_rates[2]],
			"cost": _tent.upgrade_costs[7]
		}
	]


## อัปเดตการแสดงผลทั้งหมด
func refresh() -> void:
	if _player == null or _tent == null:
		return

	if _coins_label != null:
		_coins_label.text = "%d" % _player.coins

	var nodes_data: Array[Dictionary] = _get_all_nodes_data()
	_rebuild_rail(nodes_data)
	_update_detail_card(nodes_data[_selected_index])


## สร้างปุ่มโหนดและเส้นเชื่อมต่อบนราง
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
		var tool_name: String = String(data["tool_name"])
		var tool_icon: Texture2D = _get_tool_icon(tool_name)

		# วาดปุ่มโหนด
		var node_btn: Button = Button.new()
		node_btn.custom_minimum_size = Vector2(54, 50)
		node_btn.focus_mode = Control.FOCUS_NONE

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

		# จัดวางไอคอนและตัวเลขโรมันภายในปุ่ม
		var margin_c: MarginContainer = MarginContainer.new()
		margin_c.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin_c.add_theme_constant_override("margin_left", 4)
		margin_c.add_theme_constant_override("margin_top", 4)
		margin_c.add_theme_constant_override("margin_right", 4)
		margin_c.add_theme_constant_override("margin_bottom", 4)

		var vbox_c: VBoxContainer = VBoxContainer.new()
		vbox_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox_c.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_c.add_theme_constant_override("separation", 2)

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture = tool_icon
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.custom_minimum_size = Vector2(20, 20)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var num_lbl: Label = Label.new()
		num_lbl.text = String(data["numeral"])
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", FONT_PEABERRY)
		num_lbl.add_theme_font_size_override("font_size", 10)
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		vbox_c.add_child(icon_rect)
		vbox_c.add_child(num_lbl)
		margin_c.add_child(vbox_c)
		node_btn.add_child(margin_c)

		# การแต่งสีตามสถานะ (Crafted / Ready / Locked)
		if is_owned:
			# Crafted (Pine/Moss Green)
			style.bg_color = Color(0.14, 0.22, 0.14, 0.95)
			style.border_color = Color(0.38, 0.62, 0.35, 0.9)
			icon_rect.modulate = Color(0.85, 1.0, 0.85)
			num_lbl.add_theme_color_override("font_color", Color(0.70, 0.95, 0.70))
		elif is_current_target:
			# Ready to Craft (Warm Campfire Hearth)
			style.bg_color = Color(0.30, 0.17, 0.08, 0.95)
			style.border_color = Color(0.98, 0.60, 0.20, 1.0)
			icon_rect.modulate = Color(1.0, 0.90, 0.70)
			num_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
		else:
			# Locked (Charcoal Bark)
			style.bg_color = Color(0.09, 0.07, 0.06, 0.8)
			style.border_color = Color(0.24, 0.19, 0.16, 0.6)
			icon_rect.modulate = Color(0.40, 0.36, 0.34, 0.7)
			num_lbl.add_theme_color_override("font_color", Color(0.48, 0.44, 0.40, 0.7))

		# ไฮไลต์โหนดที่ผู้เล่นกำลังเลือกดูอยู่
		if is_selected:
			style.border_color = Color(1.0, 0.88, 0.45, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3

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
			var is_tool_transition: bool = (i == 2 or i == 5)

			var line_panel: Panel = Panel.new()
			line_panel.custom_minimum_size = Vector2(26 if is_tool_transition else 18, 3)
			line_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			var line_style: StyleBoxFlat = StyleBoxFlat.new()
			if is_owned and next_owned:
				line_style.bg_color = Color(0.38, 0.62, 0.35, 0.85)
			elif is_owned and is_current_target:
				line_style.bg_color = Color(0.98, 0.60, 0.20, 0.85)
			else:
				line_style.bg_color = Color(0.22, 0.17, 0.14, 0.6)

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
	var tool_name: String = String(data["tool_name"])

	if _detail_icon != null:
		_detail_icon.texture = _get_tool_icon(tool_name)
	if _detail_tier != null:
		_detail_tier.text = String(data["tier"])

	_card_title.text = "%s : %s" % [String(data["tool_name"]), String(data["title"])]
	_card_desc.text = String(data["desc"])
	_card_stats.text = String(data["stats"])

	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2

	if is_owned:
		_card_status.text = "✓ CRAFTED & EQUIPPED"
		_card_status.add_theme_color_override("font_color", Color(0.48, 0.88, 0.45, 1.0))
		_action_button.text = "✓ ALREADY CRAFTED"
		_action_button.disabled = true
		btn_style.bg_color = Color(0.14, 0.20, 0.14, 0.85)
		btn_style.border_color = Color(0.25, 0.40, 0.25, 0.7)
		_action_button.add_theme_stylebox_override("disabled", btn_style)

	elif is_current_target:
		_card_status.text = "READY TO CRAFT"
		_card_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35, 1.0))

		if _player.coins >= cost:
			_action_button.text = "[ E ] CRAFT UPGRADE — %d COINS" % cost
			_action_button.disabled = false
			btn_style.bg_color = Color(0.85, 0.48, 0.16, 1.0)
			btn_style.border_color = Color(1.0, 0.75, 0.40, 1.0)
			_action_button.add_theme_stylebox_override("normal", btn_style)
			_action_button.add_theme_stylebox_override("hover", btn_style)
			_action_button.add_theme_stylebox_override("pressed", btn_style)
		else:
			_action_button.text = "NEEDS %d COINS (HAVE %d)" % [cost, _player.coins]
			_action_button.disabled = true
			btn_style.bg_color = Color(0.24, 0.16, 0.12, 0.85)
			btn_style.border_color = Color(0.42, 0.28, 0.20, 0.7)
			_action_button.add_theme_stylebox_override("disabled", btn_style)

	else:
		_card_status.text = "LOCKED"
		_card_status.add_theme_color_override("font_color", Color(0.55, 0.48, 0.42, 1.0))
		_action_button.text = "LOCKED — CRAFT PREVIOUS TIER FIRST"
		_action_button.disabled = true
		btn_style.bg_color = Color(0.11, 0.09, 0.08, 0.7)
		btn_style.border_color = Color(0.22, 0.18, 0.15, 0.5)
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

	_tent.notify_upgrade_purchased(step, String(data["title"]), cost)
	_tent.update_label_display(_player.upgrade_step, _player.coins)
	upgrade_completed.emit(step, String(data["title"]))

	# ขยับโฟกัสไปยังโหนดถัดไปอัตโนมัติ
	_selected_index = clampi(_player.upgrade_step + 1, 0, 8)
	refresh()

	# Micro punch บน action button เพื่อความรู้สึก tactile
	if _action_button != null:
		_action_button.pivot_offset = _action_button.size / 2.0
		var punch_tween: Tween = create_tween()
		punch_tween.tween_property(_action_button, "scale", Vector2(1.04, 1.04), 0.06)
		punch_tween.tween_property(_action_button, "scale", Vector2.ONE, 0.08)

class_name SkillTreeUI
extends CanvasLayer

## ส่งสัญญาณเมื่อหน้าต่าง Skill Tree ปิดลง
signal closed()

## ส่งสัญญาณเมื่อมีการอัพเกรดสำเร็จ
signal upgrade_completed(step: int, title: String)

var _player: Player = null
var _tent: Tent = null

## โหนด UI หลัก
@onready var _root_control: Control = $RootControl
@onready var _coins_label: Label = $RootControl/ModalPanel/MarginContainer/VBox/Header/CoinsBadge/CoinsLabel
@onready var _track_hbox: HBoxContainer = $RootControl/ModalPanel/MarginContainer/VBox/ScrollContainer/TrackHBox
@onready var _scroll_container: ScrollContainer = $RootControl/ModalPanel/MarginContainer/VBox/ScrollContainer
@onready var _close_button: Button = $RootControl/ModalPanel/MarginContainer/VBox/Header/CloseButton


func _ready() -> void:
	visible = false
	if _close_button != null:
		_close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_E:
			get_viewport().set_input_as_handled()
			close()


## เปิดหน้าต่าง Skill Tree
func open(player: Player, tent: Tent) -> void:
	_player = player
	_tent = tent
	visible = true
	refresh()


## ปิดหน้าต่าง Skill Tree
func close() -> void:
	visible = false
	closed.emit()


## อัปเดตการแสดงผลของ Skill Tree แนวนอนทั้งหมด
func refresh() -> void:
	if _player == null or _tent == null or _track_hbox == null:
		return

	# อัปเดตจำนวนเงินปัจจุบัน
	if _coins_label != null:
		_coins_label.text = "🪙 Coins: %d" % _player.coins

	# ลบโหนดเก่าใน Track แนวนอนออกก่อน
	for child: Node in _track_hbox.get_children():
		child.queue_free()

	# ข้อมูลโหนดทั้งหมด 9 ขั้น เรียงต่อกันเป็นเส้นตรงแนวนอน
	var all_nodes: Array[Dictionary] = [
		{
			"category": "✋ HANDS",
			"cat_color": Color(1.0, 0.75, 0.35, 1.0),
			"is_starter": true,
			"step": -1,
			"title": "Lv.1 Hands",
			"stats": "Cap: %d leaves" % _tent.hands_capacities[0],
			"desc": "Starter"
		},
		{
			"category": "✋ HANDS",
			"cat_color": Color(1.0, 0.75, 0.35, 1.0),
			"is_starter": false,
			"step": 0,
			"title": "Lv.2 Pockets",
			"stats": "Cap: %d leaves" % _tent.hands_capacities[1],
			"desc": "+%d Capacity" % (_tent.hands_capacities[1] - _tent.hands_capacities[0])
		},
		{
			"category": "✋ HANDS",
			"cat_color": Color(1.0, 0.75, 0.35, 1.0),
			"is_starter": false,
			"step": 1,
			"title": "Lv.3 Leaf Bag",
			"stats": "Cap: %d leaves" % _tent.hands_capacities[2],
			"desc": "Max Capacity"
		},
		{
			"category": "🧹 BROOM",
			"cat_color": Color(0.4, 0.85, 0.75, 1.0),
			"is_starter": false,
			"step": 2,
			"title": "Lv.1 Broom",
			"stats": "Sweep: %.0f\nCD: %.2fs" % [_tent.broom_sweeps[0], _tent.broom_cooldowns[0]],
			"desc": "Unlock Broom"
		},
		{
			"category": "🧹 BROOM",
			"cat_color": Color(0.4, 0.85, 0.75, 1.0),
			"is_starter": false,
			"step": 3,
			"title": "Lv.2 Wide Sweep",
			"stats": "Sweep: %.0f\nCD: %.2fs" % [_tent.broom_sweeps[1], _tent.broom_cooldowns[1]],
			"desc": "Faster & Wider"
		},
		{
			"category": "🧹 BROOM",
			"cat_color": Color(0.4, 0.85, 0.75, 1.0),
			"is_starter": false,
			"step": 4,
			"title": "Lv.3 Master",
			"stats": "Sweep: %.0f\nCD: %.2fs" % [_tent.broom_sweeps[2], _tent.broom_cooldowns[2]],
			"desc": "Max Broom Tier"
		},
		{
			"category": "💨 BLOWER",
			"cat_color": Color(0.45, 0.75, 1.0, 1.0),
			"is_starter": false,
			"step": 5,
			"title": "Lv.1 Blower",
			"stats": "Blow: %.0f/s\nContinuous" % _tent.blower_rates[0],
			"desc": "Unlock Blower"
		},
		{
			"category": "💨 BLOWER",
			"cat_color": Color(0.45, 0.75, 1.0, 1.0),
			"is_starter": false,
			"step": 6,
			"title": "Lv.2 Turbo Jet",
			"stats": "Blow: %.0f/s\nContinuous" % _tent.blower_rates[1],
			"desc": "High Power"
		},
		{
			"category": "💨 BLOWER",
			"cat_color": Color(0.45, 0.75, 1.0, 1.0),
			"is_starter": false,
			"step": 7,
			"title": "Lv.3 Vortex",
			"stats": "Blow: %.0f/s\nContinuous" % _tent.blower_rates[2],
			"desc": "Max Blower Tier"
		}
	]

	for i: int in range(all_nodes.size()):
		var data: Dictionary = all_nodes[i]
		var is_starter: bool = bool(data["is_starter"])
		var step: int = int(data["step"])
		var is_owned: bool = is_starter or (step >= 0 and _player.upgrade_step > step)
		var is_active: bool = not is_starter and (_player.upgrade_step == step)

		# สร้างการ์ดแสดงผลแนวนอน
		var card: PanelContainer = _create_node_card(data, is_owned, is_active)
		_track_hbox.add_child(card)

		# เชื่อมด้วยลูกศรแนวนอน ➔ ระหว่างทุกโหนด
		if i < all_nodes.size() - 1:
			var arrow: Label = Label.new()
			arrow.text = "➔"
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow.add_theme_font_size_override("font_size", 16)

			if is_owned and (all_nodes[i + 1]["is_starter"] or _player.upgrade_step > int(all_nodes[i + 1]["step"])):
				arrow.add_theme_color_override("font_color", Color(0.35, 0.85, 0.4, 0.9))
			elif is_active:
				arrow.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 0.9))
			else:
				arrow.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4, 0.5))

			_track_hbox.add_child(arrow)


## สร้างการ์ดของแต่ละโหนดในแถวแนวนอน
func _create_node_card(data: Dictionary, is_owned: bool, is_active: bool) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(104, 280)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# 1. แถบประเภทอุปกรณ์
	var cat_label: Label = Label.new()
	cat_label.text = String(data["category"])
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.add_theme_font_size_override("font_size", 10)
	cat_label.add_theme_color_override("font_color", data["cat_color"] as Color)
	vbox.add_child(cat_label)

	# 2. ชื่อโหนด
	var title_label: Label = Label.new()
	title_label.text = String(data["title"])
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title_label)

	# 3. คำอธิบายบทบาท
	var desc_label: Label = Label.new()
	desc_label.text = String(data["desc"])
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	vbox.add_child(desc_label)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# 4. รายละเอียดสเตตัส
	var stats_label: Label = Label.new()
	stats_label.text = String(data["stats"])
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_label)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 5. ปุ่มหรือป้ายสถานะ
	var step: int = int(data["step"])
	if is_owned:
		card_style.bg_color = Color(0.12, 0.24, 0.15, 0.9)
		card_style.border_color = Color(0.35, 0.85, 0.4, 1.0)
		title_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.55, 1.0))
		stats_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85, 1.0))

		var owned_lbl: Label = Label.new()
		owned_lbl.text = "✔ OWNED"
		owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_lbl.add_theme_font_size_override("font_size", 11)
		owned_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.45, 1.0))
		vbox.add_child(owned_lbl)

	elif is_active:
		var cost: int = _tent.upgrade_costs[step]
		var can_afford: bool = _player.coins >= cost

		card_style.bg_color = Color(0.26, 0.18, 0.10, 0.95)
		card_style.border_color = Color(1.0, 0.65, 0.2, 1.0)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
		stats_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_font_size_override("font_size", 10)

		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
		btn_style.corner_radius_top_left = 4
		btn_style.corner_radius_top_right = 4
		btn_style.corner_radius_bottom_left = 4
		btn_style.corner_radius_bottom_right = 4

		if can_afford:
			btn.text = "▲ UPGRADE\n%dG" % cost
			btn_style.bg_color = Color(0.85, 0.45, 0.15, 1.0)
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.pressed.connect(func() -> void: _on_upgrade_pressed(step))
		else:
			btn.text = "🔒 NEED\n%dG" % cost
			btn.disabled = true
			btn_style.bg_color = Color(0.3, 0.2, 0.15, 1.0)
			btn.add_theme_stylebox_override("disabled", btn_style)

		vbox.add_child(btn)

	else:
		card_style.bg_color = Color(0.10, 0.10, 0.13, 0.65)
		card_style.border_color = Color(0.25, 0.25, 0.3, 0.8)
		title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
		stats_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 1.0))

		var locked_lbl: Label = Label.new()
		var cost: int = _tent.upgrade_costs[step] if step >= 0 and step < _tent.upgrade_costs.size() else 0
		locked_lbl.text = "🔒 LOCKED\n(%dG)" % cost
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 9)
		locked_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
		vbox.add_child(locked_lbl)

	card.add_theme_stylebox_override("panel", card_style)
	return card


## เมื่อกดปุ่มอัพเกรด
func _on_upgrade_pressed(step: int) -> void:
	if _player == null or _tent == null:
		return

	if step != _player.upgrade_step:
		return

	var info: Dictionary = _tent.get_upgrade_info(step)
	if not info.get("valid", false):
		return

	var cost: int = int(info["cost"])
	if _player.coins < cost:
		return

	# หักเงินและดำเนินการอัพเกรด
	_player.coins -= cost
	_player.coins_changed.emit(_player.coins)
	_player.apply_upgrade_step(step)
	_player.upgrade_step += 1

	_tent.upgrade_purchased.emit(step, String(info["title"]), cost)
	_tent.update_label_display(_player.upgrade_step, _player.coins)
	upgrade_completed.emit(step, String(info["title"]))

	# รีเฟรชหน้าต่างทันทีเพื่อให้เห็นความเปลี่ยนแปลงในแถวแนวนอน
	refresh()

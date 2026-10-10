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
@onready var _hands_nodes_box: VBoxContainer = $RootControl/ModalPanel/MarginContainer/VBox/Columns/HandsColumn/NodesBox
@onready var _broom_nodes_box: VBoxContainer = $RootControl/ModalPanel/MarginContainer/VBox/Columns/BroomColumn/NodesBox
@onready var _blower_nodes_box: VBoxContainer = $RootControl/ModalPanel/MarginContainer/VBox/Columns/BlowerColumn/NodesBox
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


## อัปเดตการแสดงผลของ Skill Tree ทั้งหมด
func refresh() -> void:
	if _player == null or _tent == null:
		return

	# อัปเดตจำนวนเงินปัจจุบัน
	if _coins_label != null:
		_coins_label.text = "🪙 Coins: %d" % _player.coins

	# ล้างและสร้างการ์ดของแต่ละคอลัมน์ใหม่
	_populate_column(_hands_nodes_box, [
		{"type": "starter", "title": "Lv.1 Basic Hands", "stats": "Leaf Capacity: %d" % _tent.hands_capacities[0]},
		{"step": 0, "title": "Lv.2 Deep Pockets", "stats": "Leaf Capacity: %d (+%d)" % [_tent.hands_capacities[1], _tent.hands_capacities[1] - _tent.hands_capacities[0]]},
		{"step": 1, "title": "Lv.3 Leaf Bag", "stats": "Leaf Capacity: %d (Max)" % _tent.hands_capacities[2]}
	])

	_populate_column(_broom_nodes_box, [
		{"step": 2, "title": "Lv.1 Bamboo Broom", "stats": "Sweep: %.0f | CD: %.2fs" % [_tent.broom_sweeps[0], _tent.broom_cooldowns[0]]},
		{"step": 3, "title": "Lv.2 Wide Sweep", "stats": "Sweep: %.0f | CD: %.2fs" % [_tent.broom_sweeps[1], _tent.broom_cooldowns[1]]},
		{"step": 4, "title": "Lv.3 Master Sweeper", "stats": "Sweep: %.0f | CD: %.2fs (Max)" % [_tent.broom_sweeps[2], _tent.broom_cooldowns[2]]}
	])

	_populate_column(_blower_nodes_box, [
		{"step": 5, "title": "Lv.1 Leaf Blower", "stats": "Continuous Blow: %.0f/s" % _tent.blower_rates[0]},
		{"step": 6, "title": "Lv.2 Turbo Jet", "stats": "Continuous Blow: %.0f/s" % _tent.blower_rates[1]},
		{"step": 7, "title": "Lv.3 Hurricane Vortex", "stats": "Continuous Blow: %.0f/s (Max)" % _tent.blower_rates[2]}
	])


## สร้างโหนดแสดงผลในแต่ละคอลัมน์
func _populate_column(container: VBoxContainer, nodes_data: Array) -> void:
	if container == null:
		return

	# ลบโหนดเก่าออกก่อน
	for child: Node in container.get_children():
		child.queue_free()

	for i: int in range(nodes_data.size()):
		var data: Dictionary = nodes_data[i] as Dictionary
		var is_starter: bool = data.has("type") and String(data["type"]) == "starter"
		var step: int = int(data.get("step", -1))
		var title: String = String(data["title"])
		var stats: String = String(data["stats"])

		# สร้างการ์ดของโหนด
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(240, 85)

		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.corner_radius_top_left = 6
		card_style.corner_radius_top_right = 6
		card_style.corner_radius_bottom_left = 6
		card_style.corner_radius_bottom_right = 6
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.border_width_top = 2
		card_style.border_width_bottom = 2

		var content_vbox: VBoxContainer = VBoxContainer.new()
		content_vbox.add_theme_constant_override("separation", 3)
		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		margin.add_child(content_vbox)
		card.add_child(margin)

		# ชื่อโหนด
		var title_label: Label = Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 13)
		content_vbox.add_child(title_label)

		# ข้อมูลสเตตัส
		var stats_label: Label = Label.new()
		stats_label.text = stats
		stats_label.add_theme_font_size_override("font_size", 11)
		content_vbox.add_child(stats_label)

		# สถานะของโหนด: 1. Owned, 2. Current Active (พร้อมอัพ), 3. Locked
		var is_owned: bool = is_starter or (step >= 0 and _player.upgrade_step > step)
		var is_active: bool = not is_starter and (_player.upgrade_step == step)

		if is_owned:
			# ผ่านการอัพเกรดแล้ว
			card_style.bg_color = Color(0.12, 0.22, 0.14, 0.85)
			card_style.border_color = Color(0.3, 0.75, 0.35, 1.0)
			title_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1.0))
			stats_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.8, 1.0))

			var owned_badge: Label = Label.new()
			owned_badge.text = "✔ OWNED"
			owned_badge.add_theme_font_size_override("font_size", 11)
			owned_badge.add_theme_color_override("font_color", Color(0.4, 0.95, 0.45, 1.0))
			content_vbox.add_child(owned_badge)

		elif is_active:
			# ขั้นปัจจุบันที่สามารถอัพเกรดได้
			var cost: int = _tent.upgrade_costs[step]
			var can_afford: bool = _player.coins >= cost

			card_style.bg_color = Color(0.24, 0.18, 0.10, 0.95)
			card_style.border_color = Color(1.0, 0.65, 0.2, 1.0)
			title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
			stats_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))

			var upgrade_btn: Button = Button.new()
			upgrade_btn.custom_minimum_size = Vector2(0, 26)
			upgrade_btn.add_theme_font_size_override("font_size", 11)

			var btn_style: StyleBoxFlat = StyleBoxFlat.new()
			btn_style.corner_radius_top_left = 4
			btn_style.corner_radius_top_right = 4
			btn_style.corner_radius_bottom_left = 4
			btn_style.corner_radius_bottom_right = 4

			if can_afford:
				upgrade_btn.text = "▲ UPGRADE (%dG)" % cost
				btn_style.bg_color = Color(0.85, 0.45, 0.15, 1.0)
				upgrade_btn.add_theme_stylebox_override("normal", btn_style)
				upgrade_btn.pressed.connect(func() -> void: _on_upgrade_pressed(step))
			else:
				upgrade_btn.text = "🔒 NEED %dG (Have %dG)" % [cost, _player.coins]
				upgrade_btn.disabled = true
				btn_style.bg_color = Color(0.3, 0.2, 0.15, 1.0)
				upgrade_btn.add_theme_stylebox_override("disabled", btn_style)

			content_vbox.add_child(upgrade_btn)

		else:
			# ล็อกอยู่ ต้องอัพเกรดขั้นก่อนหน้าให้เสร็จก่อน
			card_style.bg_color = Color(0.10, 0.10, 0.12, 0.6)
			card_style.border_color = Color(0.25, 0.25, 0.3, 0.8)
			title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
			stats_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 1.0))

			var locked_badge: Label = Label.new()
			var cost: int = _tent.upgrade_costs[step] if step >= 0 and step < _tent.upgrade_costs.size() else 0
			locked_badge.text = "🔒 LOCKED (%dG)" % cost
			locked_badge.add_theme_font_size_override("font_size", 10)
			locked_badge.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
			content_vbox.add_child(locked_badge)

		card.add_theme_stylebox_override("panel", card_style)
		container.add_child(card)

		# เพิ่มลูกศรเชื่อมโยงระหว่างโหนดในคอลัมน์เดียวกัน
		if i < nodes_data.size() - 1:
			var arrow_label: Label = Label.new()
			arrow_label.text = "▼"
			arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow_label.add_theme_font_size_override("font_size", 10)
			var arrow_color: Color = Color(0.3, 0.75, 0.35, 0.8) if (step >= 0 and _player.upgrade_step > step) else Color(0.4, 0.4, 0.45, 0.5)
			arrow_label.add_theme_color_override("font_color", arrow_color)
			container.add_child(arrow_label)


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

	# รีเฟรชหน้าต่างทันทีเพื่อให้เห็นความเปลี่ยนแปลง
	refresh()

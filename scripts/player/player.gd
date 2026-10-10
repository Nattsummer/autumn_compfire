class_name Player
extends CharacterBody2D

signal leaves_changed(current: int, maximum: int)
signal coins_changed(new_amount: int)
signal tool_changed(new_tool: ToolType)

enum ToolType {
	HANDS,
	BROOM,
	BLOWER
}

## ความเร็วการเดินแนวนอน (Pixel / วินาที)
@export var move_speed: float = 160.0

## ค่าแรงโน้มถ่วงจำลอง (Pixel / วินาที^2)
@export var gravity: float = 980.0

## ความจุสูงสุดของการเก็บใบไม้ด้วยมือเปล่า
@export var max_hand_capacity: int = 2

## จำนวนใบไม้สูงสุดที่ไม้กวาดสามารถกวาดได้ต่อครั้ง
@export var max_broom_sweep: float = 5.0

## ระยะเวลาคูลดาวน์ของไม้กวาด (วินาทีต่อครั้ง)
@export var broom_cooldown: float = 0.60

## อัตราการเป่าของเครื่องเป่าลม (ใบไม้ต่อวินาทีเมื่อกดค้าง)
@export var blower_rate: float = 30.0

## เงินสะสมของผู้เล่น
@export var coins: int = 0

## ลำดับขั้นการอัพเกรดปัจจุบัน (0 ถึง 7 สำหรับ Linear Upgrade 8 ขั้น)
@export var upgrade_step: int = 0

## เลเวลปัจจุบันของแต่ละอุปกรณ์ (1 ถึง 3)
@export var hands_level: int = 1
@export var broom_level: int = 0
@export var blower_level: int = 0

## รายการอุปกรณ์ที่ปลดล็อกแล้วสำหรับสลับใช้งาน
var unlocked_tools: Array[ToolType] = [ToolType.HANDS]

## ไอเทมที่กำลังถืออยู่ปัจจุบัน
var current_tool: ToolType = ToolType.HANDS

## ทิศทางที่ตัวละครกำลังหันหน้า (1 = ขวา, -1 = ซ้าย)
var facing_direction: int = 1

## จำนวนใบไม้ที่ถืออยู่ในมือปัจจุบัน (สำหรับมือเปล่า)
var carried_leaves: int = 0

## ตัวจับเวลาคูลดาวน์ของไม้กวาด
var _broom_cooldown_timer: float = 0.0

## บัฟเฟอร์สะสมเศษใบไม้สำหรับเครื่องเป่าลมเพื่อส่งเข้ากองไฟ
var _leaf_burn_buffer: float = 0.0

## อ้างอิงระบบและออบเจ็กต์ในฉาก
var _leaf_grid: LeafGrid = null
var _campfire: Campfire = null
var _tent: Tent = null

## โหนด Label แสดงสถานะเงินและใบไม้
@onready var _status_label: Label = $StatusLabel


func _ready() -> void:
	_leaf_grid = get_tree().get_first_node_in_group("leaf_grid") as LeafGrid
	_campfire = get_tree().get_first_node_in_group("campfire") as Campfire
	_tent = get_tree().get_first_node_in_group("tent") as Tent

	# เริ่มต้นรายการอุปกรณ์ที่ปลดล็อกตามเลเวล
	unlocked_tools.clear()
	unlocked_tools.append(ToolType.HANDS)
	if broom_level > 0:
		unlocked_tools.append(ToolType.BROOM)
	if blower_level > 0:
		unlocked_tools.append(ToolType.BLOWER)

	if _tent != null:
		_tent.update_label_display(upgrade_step, coins)

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	# สลับอุปกรณ์ที่ปลดล็อกแล้ว (Q หรือ Tab)
	if event.is_action_pressed("switch_tool"):
		cycle_unlocked_tool()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Q or event.physical_keycode == KEY_TAB:
			cycle_unlocked_tool()


## สลับใช้อุปกรณ์ในกลุ่มที่ปลดล็อกแล้วแบบวนรอบ
func cycle_unlocked_tool() -> void:
	if unlocked_tools.size() <= 1:
		return

	var current_idx: int = unlocked_tools.find(current_tool)
	var next_idx: int = (current_idx + 1) % unlocked_tools.size()
	current_tool = unlocked_tools[next_idx]
	tool_changed.emit(current_tool)
	_update_ui()


func _physics_process(delta: float) -> void:
	# อัปเดตเวลานับถอยหลังคูลดาวน์ของไม้กวาด
	if _broom_cooldown_timer > 0.0:
		_broom_cooldown_timer = maxf(0.0, _broom_cooldown_timer - delta)

	_apply_gravity(delta)
	_handle_movement()
	_handle_interactions(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	# ใช้แรงโน้มถ่วงเมื่อตัวละครไม่อยู่บนพื้น
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


func _handle_movement() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")

	# Fallback กรณีที่ไม่ได้รันผ่าน Input Map ปกติ
	if direction == 0.0:
		direction = Input.get_axis("ui_left", "ui_right")

	# บันทึกทิศทางการหันหน้า
	if direction > 0.0:
		facing_direction = 1
	elif direction < 0.0:
		facing_direction = -1

	velocity.x = direction * move_speed


func _handle_interactions(delta: float) -> void:
	# ค้นหาโหนดหากยังไม่ได้เชื่อมต่อ
	if _campfire == null:
		_campfire = get_tree().get_first_node_in_group("campfire") as Campfire
	if _leaf_grid == null:
		_leaf_grid = get_tree().get_first_node_in_group("leaf_grid") as LeafGrid
	if _tent == null:
		_tent = get_tree().get_first_node_in_group("tent") as Tent

	# 1. ปฏิสัมพันธ์กับเต็นท์ (Tent) - สถานีอัพเกรดแบบเชิงเส้น (Linear Upgrade Station)
	if _tent != null and _tent.is_in_range(global_position.x):
		var info: Dictionary = _tent.get_upgrade_info(upgrade_step)
		if info.get("valid", false):
			var title: String = String(info["title"])
			var desc: String = String(info["desc"])
			var cost: int = int(info["cost"])
			var switch_hint: String = " | [Q] Switch (%s)" % _get_tool_name(current_tool) if unlocked_tools.size() > 1 else ""

			if coins >= cost:
				_set_prompt("[Tent Upgrade] %s (%s)\n[E] Upgrade (%dG)%s" % [title, desc, cost, switch_hint])
				if Input.is_action_just_pressed("interact"):
					coins -= cost
					coins_changed.emit(coins)
					_apply_upgrade_step(upgrade_step)
					upgrade_step += 1
					_tent.upgrade_purchased.emit(upgrade_step - 1, title, cost)
					_tent.update_label_display(upgrade_step, coins)
					_update_ui()
			else:
				_set_prompt("[Tent Upgrade] %s (%s)\nNeed %dG (Have %dG)%s" % [title, desc, cost, coins, switch_hint])
		else:
			var switch_hint_max: String = "\n[Q] Switch Tool: %s" % _get_tool_name(current_tool) if unlocked_tools.size() > 1 else ""
			_set_prompt("[Tent] All Upgrades Maxed!\nCoins: %d%s" % [coins, switch_hint_max])
		return

	# 2. ปฏิสัมพันธ์ตามประเภทไอเทมที่กำลังถือ
	match current_tool:
		ToolType.BROOM:
			_handle_broom_interaction()
		ToolType.BLOWER:
			_handle_blower_interaction(delta)
		ToolType.HANDS:
			_handle_hands_interaction()


## นำผลการอัพเกรดแต่ละขั้นมาปรับใช้กับตัวละคร
func _apply_upgrade_step(step: int) -> void:
	match step:
		0: # Hands Lv 2
			hands_level = 2
			max_hand_capacity = _tent.hands_capacities[1] if _tent != null else 5
			leaves_changed.emit(carried_leaves, max_hand_capacity)
		1: # Hands Lv 3
			hands_level = 3
			max_hand_capacity = _tent.hands_capacities[2] if _tent != null else 10
			leaves_changed.emit(carried_leaves, max_hand_capacity)
		2: # Unlock Broom Lv 1
			broom_level = 1
			max_broom_sweep = _tent.broom_sweeps[0] if _tent != null else 5.0
			broom_cooldown = _tent.broom_cooldowns[0] if _tent != null else 0.60
			if not unlocked_tools.has(ToolType.BROOM):
				unlocked_tools.append(ToolType.BROOM)
			current_tool = ToolType.BROOM
			tool_changed.emit(current_tool)
		3: # Broom Lv 2
			broom_level = 2
			max_broom_sweep = _tent.broom_sweeps[1] if _tent != null else 15.0
			broom_cooldown = _tent.broom_cooldowns[1] if _tent != null else 0.40
		4: # Broom Lv 3
			broom_level = 3
			max_broom_sweep = _tent.broom_sweeps[2] if _tent != null else 35.0
			broom_cooldown = _tent.broom_cooldowns[2] if _tent != null else 0.25
		5: # Unlock Blower Lv 1
			blower_level = 1
			blower_rate = _tent.blower_rates[0] if _tent != null else 30.0
			if not unlocked_tools.has(ToolType.BLOWER):
				unlocked_tools.append(ToolType.BLOWER)
			current_tool = ToolType.BLOWER
			tool_changed.emit(current_tool)
		6: # Blower Lv 2
			blower_level = 2
			blower_rate = _tent.blower_rates[1] if _tent != null else 80.0
		7: # Blower Lv 3
			blower_level = 3
			blower_rate = _tent.blower_rates[2] if _tent != null else 200.0


## การทำงานเมื่อถือไม้กวาด (Broom) พร้อมระบบคูลดาวน์
func _handle_broom_interaction() -> void:
	if _leaf_grid == null:
		return

	var available: float = _leaf_grid.get_leaf_count_at(global_position.x)
	var sweep_target_x: float = global_position.x + (float(facing_direction) * _leaf_grid.cell_size)
	var arrow: String = "->" if facing_direction > 0 else "<-"

	# หากกำลังติดคูลดาวน์
	if _broom_cooldown_timer > 0.0:
		_set_prompt("[Broom] Cooldown (%.1fs)" % _broom_cooldown_timer)
		return

	# ตรวจสอบว่าทิศทางที่กวาดไปตกอยู่ในระยะของกองไฟหรือไม่
	var sweeping_into_fire: bool = _campfire != null and _campfire.is_in_range(sweep_target_x)

	if sweeping_into_fire:
		if available >= 0.5:
			var mult: float = _campfire.get_reward_multiplier()
			var sweep_amount: float = minf(available, max_broom_sweep)
			var est_reward: int = int(round(float(int(round(sweep_amount)) * _campfire.base_reward_per_leaf) * mult))
			_set_prompt("[Broom] Coins: %d\n[E] Sweep into Fire (+%dG)" % [coins, est_reward])

			if Input.is_action_just_pressed("interact"):
				var harvested: float = _leaf_grid.harvest_leaves_float(global_position.x, max_broom_sweep)
				var burn_count: int = int(round(harvested))
				if burn_count > 0:
					var reward: int = _campfire.add_leaves(burn_count)
					coins += reward
					coins_changed.emit(coins)
					if _tent != null:
						_tent.update_label_display(upgrade_step, coins)
				_broom_cooldown_timer = broom_cooldown
		else:
			_set_prompt("[Broom Lv.%d] Coins: %d\n(No leaves near fire)" % [broom_level, coins])
	else:
		if available >= 0.5:
			_set_prompt("[Broom Lv.%d] Coins: %d\n[E] Sweep %s (Max %.0f)" % [broom_level, coins, arrow, max_broom_sweep])
			if Input.is_action_just_pressed("interact"):
				_leaf_grid.move_leaves(global_position.x, sweep_target_x, max_broom_sweep)
				_broom_cooldown_timer = broom_cooldown
		else:
			_set_prompt("[Broom Lv.%d] Coins: %d\n(No leaves to sweep)" % [broom_level, coins])


## การทำงานเมื่อถือเครื่องเป่าลม (Blower)
func _handle_blower_interaction(delta: float) -> void:
	if _leaf_grid == null:
		return

	var available: float = _leaf_grid.get_leaf_count_at(global_position.x)
	var sweep_target_x: float = global_position.x + (float(facing_direction) * _leaf_grid.cell_size)
	var arrow: String = "->" if facing_direction > 0 else "<-"
	var blow_amount: float = blower_rate * delta

	# ตรวจสอบว่าเป่าเข้าไปในระยะของกองไฟหรือไม่
	var blowing_into_fire: bool = _campfire != null and _campfire.is_in_range(sweep_target_x)

	if blowing_into_fire:
		if available >= 0.1:
			_set_prompt("[Blower Lv.%d] Coins: %d\n[Hold E] Blow into Fire (%.0f/s)" % [blower_level, coins, blower_rate])
			if Input.is_action_pressed("interact"):
				var harvested: float = _leaf_grid.harvest_leaves_float(global_position.x, blow_amount)
				_leaf_burn_buffer += harvested
				# เมื่อสะสมครบจำนวนเต็มให้ส่งเข้ากองไฟและมอบเหรียญรางวัล
				if _leaf_burn_buffer >= 1.0:
					var to_burn: int = int(_leaf_burn_buffer)
					_leaf_burn_buffer -= float(to_burn)
					var reward: int = _campfire.add_leaves(to_burn)
					coins += reward
					coins_changed.emit(coins)
					if _tent != null:
						_tent.update_label_display(upgrade_step, coins)
		else:
			_set_prompt("[Blower Lv.%d] Coins: %d\n(No leaves near fire)" % [blower_level, coins])
	else:
		if available >= 0.1:
			_set_prompt("[Blower Lv.%d] Coins: %d\n[Hold E] Blow %s (%.0f/s)" % [blower_level, coins, arrow, blower_rate])
			if Input.is_action_pressed("interact"):
				_leaf_grid.move_leaves(global_position.x, sweep_target_x, blow_amount)
		else:
			_set_prompt("[Blower Lv.%d] Coins: %d\n(No leaves to blow)" % [blower_level, coins])


## การทำงานเมื่อใช้มือเปล่า (Hands)
func _handle_hands_interaction() -> void:
	var is_near_fire: bool = _campfire != null and _campfire.is_in_range(global_position.x)

	if is_near_fire:
		if carried_leaves > 0:
			var mult: float = _campfire.get_reward_multiplier()
			var est_reward: int = int(round(float(carried_leaves * _campfire.base_reward_per_leaf) * mult))
			_set_prompt("[Hands Lv.%d] Coins: %d | Leaves: %d/%d\n[E] Feed (+%dG x%.1f)" % [hands_level, coins, carried_leaves, max_hand_capacity, est_reward, mult])

			if Input.is_action_just_pressed("interact"):
				var reward: int = _campfire.add_leaves(carried_leaves)
				coins += reward
				coins_changed.emit(coins)
				if _tent != null:
					_tent.update_label_display(upgrade_step, coins)
				carried_leaves = 0
				leaves_changed.emit(0, max_hand_capacity)
		else:
			_set_prompt("[Hands Lv.%d] Coins: %d | Leaves: 0/%d\n(Need leaves)" % [hands_level, coins, max_hand_capacity])
		return

	if _leaf_grid != null:
		var available_at_feet: float = _leaf_grid.get_leaf_count_at(global_position.x)
		var can_gather: bool = carried_leaves < max_hand_capacity and available_at_feet >= 1.0

		if carried_leaves >= max_hand_capacity:
			_set_prompt("[Hands Lv.%d] Coins: %d | Leaves: %d/%d (Full)" % [hands_level, coins, carried_leaves, max_hand_capacity])
		elif can_gather:
			_set_prompt("[Hands Lv.%d] Coins: %d | Leaves: %d/%d\n[E] Pick Leaf" % [hands_level, coins, carried_leaves, max_hand_capacity])
			if Input.is_action_just_pressed("interact"):
				var gathered: int = _leaf_grid.harvest_leaves(global_position.x, 1)
				if gathered > 0:
					carried_leaves += gathered
					leaves_changed.emit(carried_leaves, max_hand_capacity)
		else:
			_set_prompt("[Hands Lv.%d] Coins: %d | Leaves: %d/%d" % [hands_level, coins, carried_leaves, max_hand_capacity])


func _get_tool_name(tool: ToolType) -> String:
	match tool:
		ToolType.HANDS:
			return "Hands Lv.%d" % hands_level
		ToolType.BROOM:
			return "Broom Lv.%d" % broom_level
		ToolType.BLOWER:
			return "Blower Lv.%d" % blower_level
		_:
			return "Unknown"


func _update_ui() -> void:
	if _status_label != null:
		match current_tool:
			ToolType.BROOM:
				_status_label.text = "[Broom Lv.%d] Coins: %d" % [broom_level, coins]
			ToolType.BLOWER:
				_status_label.text = "[Blower Lv.%d] Coins: %d" % [blower_level, coins]
			ToolType.HANDS:
				_status_label.text = "[Hands Lv.%d] Coins: %d | Leaves: %d/%d" % [hands_level, coins, carried_leaves, max_hand_capacity]


func _set_prompt(text: String) -> void:
	if _status_label != null:
		_status_label.text = text

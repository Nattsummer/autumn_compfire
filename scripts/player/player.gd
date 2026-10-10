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
@export var broom_cooldown: float = 0.45

## อัตราการเป่าของเครื่องเป่าลม (ใบไม้ต่อวินาทีเมื่อกดค้าง)
@export var blower_rate: float = 20.0

## เงินสะสมของผู้เล่น
@export var coins: int = 0

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

	# 1. ปฏิสัมพันธ์กับเต็นท์ (Tent) - หมุนเวียนเปลี่ยนไอเทม: Hands -> Broom -> Blower
	if _tent != null and _tent.is_in_range(global_position.x):
		var next_tool: ToolType
		match current_tool:
			ToolType.HANDS:
				next_tool = ToolType.BROOM
			ToolType.BROOM:
				next_tool = ToolType.BLOWER
			ToolType.BLOWER:
				next_tool = ToolType.HANDS

		_set_prompt("Tent\n[E] Equip %s" % _get_tool_name(next_tool))
		if Input.is_action_just_pressed("interact"):
			current_tool = next_tool
			tool_changed.emit(current_tool)
			_update_ui()
		return

	# 2. ปฏิสัมพันธ์ตามประเภทไอเทมที่กำลังถือ
	match current_tool:
		ToolType.BROOM:
			_handle_broom_interaction()
		ToolType.BLOWER:
			_handle_blower_interaction(delta)
		ToolType.HANDS:
			_handle_hands_interaction()


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
				_broom_cooldown_timer = broom_cooldown
		else:
			_set_prompt("[Broom] Coins: %d\n(No leaves near fire)" % coins)
	else:
		if available >= 0.5:
			_set_prompt("[Broom] Coins: %d\n[E] Sweep %s (Max 5)" % [coins, arrow])
			if Input.is_action_just_pressed("interact"):
				_leaf_grid.move_leaves(global_position.x, sweep_target_x, max_broom_sweep)
				_broom_cooldown_timer = broom_cooldown
		else:
			_set_prompt("[Broom] Coins: %d\n(No leaves to sweep)" % coins)


## การทำงานเมื่อถือเครื่องเป่าลม (Blower) - กดค้างได้ต่อเนื่อง 30 ใบ/วินาที
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
			_set_prompt("[Blower] Coins: %d\n[Hold E] Blow into Fire (30/s)" % coins)
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
		else:
			_set_prompt("[Blower] Coins: %d\n(No leaves near fire)" % coins)
	else:
		if available >= 0.1:
			_set_prompt("[Blower] Coins: %d\n[Hold E] Blow %s (30/s)" % [coins, arrow])
			if Input.is_action_pressed("interact"):
				_leaf_grid.move_leaves(global_position.x, sweep_target_x, blow_amount)
		else:
			_set_prompt("[Blower] Coins: %d\n(No leaves to blow)" % coins)


## การทำงานเมื่อใช้มือเปล่า (Hands)
func _handle_hands_interaction() -> void:
	var is_near_fire: bool = _campfire != null and _campfire.is_in_range(global_position.x)

	if is_near_fire:
		if carried_leaves > 0:
			var mult: float = _campfire.get_reward_multiplier()
			var est_reward: int = int(round(float(carried_leaves * _campfire.base_reward_per_leaf) * mult))
			_set_prompt("Coins: %d | Leaves: %d/%d\n[E] Feed (+%dG x%.1f)" % [coins, carried_leaves, max_hand_capacity, est_reward, mult])

			if Input.is_action_just_pressed("interact"):
				var reward: int = _campfire.add_leaves(carried_leaves)
				coins += reward
				coins_changed.emit(coins)
				carried_leaves = 0
				leaves_changed.emit(0, max_hand_capacity)
		else:
			_set_prompt("Coins: %d | Leaves: 0/%d\n(Need leaves)" % [coins, max_hand_capacity])
		return

	if _leaf_grid != null:
		var available_at_feet: float = _leaf_grid.get_leaf_count_at(global_position.x)
		var can_gather: bool = carried_leaves < max_hand_capacity and available_at_feet >= 1.0

		if carried_leaves >= max_hand_capacity:
			_set_prompt("Coins: %d | Leaves: %d/%d (Full)" % [coins, carried_leaves, max_hand_capacity])
		elif can_gather:
			_set_prompt("Coins: %d | Leaves: %d/%d\n[E] Pick Leaf" % [coins, carried_leaves, max_hand_capacity])
			if Input.is_action_just_pressed("interact"):
				var gathered: int = _leaf_grid.harvest_leaves(global_position.x, 1)
				if gathered > 0:
					carried_leaves += gathered
					leaves_changed.emit(carried_leaves, max_hand_capacity)
		else:
			_set_prompt("Coins: %d | Leaves: %d/%d" % [coins, carried_leaves, max_hand_capacity])


func _get_tool_name(tool: ToolType) -> String:
	match tool:
		ToolType.HANDS:
			return "Hands"
		ToolType.BROOM:
			return "Broom"
		ToolType.BLOWER:
			return "Blower"
		_:
			return "Unknown"


func _update_ui() -> void:
	if _status_label != null:
		match current_tool:
			ToolType.BROOM:
				_status_label.text = "[Broom] Coins: %d" % coins
			ToolType.BLOWER:
				_status_label.text = "[Blower] Coins: %d" % coins
			ToolType.HANDS:
				_status_label.text = "Coins: %d | Leaves: %d/%d" % [coins, carried_leaves, max_hand_capacity]


func _set_prompt(text: String) -> void:
	if _status_label != null:
		_status_label.text = text

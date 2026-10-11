class_name Player
extends CharacterBody2D

signal leaves_changed(current: int, maximum: int)
signal coins_changed(new_amount: int)
signal tool_changed(new_tool: ToolType)
signal prompt_updated(key_code: String, text: String, is_visible: bool)

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
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _sweep_leaf_particles: CPUParticles2D = $SweepLeafParticles
@onready var _sweep_wind_particles: CPUParticles2D = $SweepWindParticles
@onready var _blow_wind_particles: CPUParticles2D = $BlowWindParticles
@onready var _blow_leaves_particles: CPUParticles2D = $BlowLeavesParticles

## ตัวจับเวลาแอนิเมชัน One-shot
var _action_anim_timer: float = 0.0


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
		if not _tent.upgrade_purchased.is_connected(_on_tent_upgrade_purchased):
			_tent.upgrade_purchased.connect(_on_tent_upgrade_purchased)

	_update_ui()


func _on_tent_upgrade_purchased(_step: int, _title: String, _cost: int) -> void:
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
	_update_animations(0.0)


func _physics_process(delta: float) -> void:
	# อัปเดตเวลานับถอยหลังคูลดาวน์ของไม้กวาด
	if _broom_cooldown_timer > 0.0:
		_broom_cooldown_timer = maxf(0.0, _broom_cooldown_timer - delta)

	# หากเปิดหน้าต่าง Skill Tree อยู่ ให้หยุดการเคลื่อนที่และการกระทำอื่น
	if _tent != null and _tent.is_skill_tree_open():
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		_update_animations(delta)
		return

	_apply_gravity(delta)
	_handle_movement()
	_handle_interactions(delta)
	move_and_slide()
	_update_animations(delta)


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

	# 1. ปฏิสัมพันธ์กับเต็นท์ (Tent) - เปิดหน้าต่าง Skill Tree
	if _tent != null and _tent.is_in_range(global_position.x):
		_set_prompt("[E] Open Upgrades")
		if Input.is_action_just_pressed("interact"):
			_set_prompt("")
			_tent.open_skill_tree(self)
		return

	# 2. ปฏิสัมพันธ์ตามประเภทไอเทมที่กำลังถือ
	match current_tool:
		ToolType.BROOM:
			_update_blower_vfx(false, false)
			_handle_broom_interaction()
		ToolType.BLOWER:
			_handle_blower_interaction(delta)
		ToolType.HANDS:
			_update_blower_vfx(false, false)
			_handle_hands_interaction()


## นำผลการอัพเกรดแต่ละขั้นมาปรับใช้กับตัวละคร
func apply_upgrade_step(step: int) -> void:
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

	_update_animations(0.0)


## การทำงานเมื่อถือไม้กวาด (Broom) พร้อมระบบคูลดาวน์
func _handle_broom_interaction() -> void:
	if _leaf_grid == null:
		return

	var available: float = _leaf_grid.get_leaf_count_at(global_position.x)
	var sweep_target_x: float = global_position.x + (float(facing_direction) * _leaf_grid.cell_size)
	var arrow: String = "->" if facing_direction > 0 else "<-"

	# หากกำลังติดคูลดาวน์
	if _broom_cooldown_timer > 0.0:
		_set_prompt("Cooldown (%.1fs)" % _broom_cooldown_timer)
		return

	# ตรวจสอบว่าทิศทางที่กวาดไปตกอยู่ในระยะของกองไฟหรือไม่
	var sweeping_into_fire: bool = _campfire != null and _campfire.is_in_range(sweep_target_x)

	if sweeping_into_fire:
		if available >= 0.5:
			var mult: float = _campfire.get_reward_multiplier()
			var sweep_amount: float = minf(available, max_broom_sweep)
			var est_reward: int = int(round(float(int(round(sweep_amount)) * _campfire.base_reward_per_leaf) * mult))
			_set_prompt("[E] Sweep into Fire (+%dG)" % est_reward)

			if Input.is_action_just_pressed("interact"):
				_play_action_animation("broom_sweep", 0.4)
				_trigger_sweep_hit_vfx(sweep_amount)
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
			_set_prompt("")
			if Input.is_action_just_pressed("interact"):
				_play_action_animation("broom_sweep", 0.4)
				_trigger_sweep_wind_vfx()
				_broom_cooldown_timer = broom_cooldown
	else:
		if available >= 0.5:
			var sweep_amount: float = minf(available, max_broom_sweep)
			_set_prompt("[E] Sweep %s" % arrow)
			if Input.is_action_just_pressed("interact"):
				_play_action_animation("broom_sweep", 0.4)
				_trigger_sweep_hit_vfx(sweep_amount)
				_leaf_grid.move_leaves(global_position.x, sweep_target_x, max_broom_sweep)
				_broom_cooldown_timer = broom_cooldown
		else:
			_set_prompt("")
			if Input.is_action_just_pressed("interact"):
				_play_action_animation("broom_sweep", 0.4)
				_trigger_sweep_wind_vfx()
				_broom_cooldown_timer = broom_cooldown


## การทำงานเมื่อถือเครื่องเป่าลม (Blower)
func _handle_blower_interaction(delta: float) -> void:
	if _leaf_grid == null:
		_update_blower_vfx(false, false)
		return

	var available: float = _leaf_grid.get_leaf_count_at(global_position.x)
	var sweep_target_x: float = global_position.x + (float(facing_direction) * _leaf_grid.cell_size)
	var arrow: String = "->" if facing_direction > 0 else "<-"
	var blow_amount: float = blower_rate * delta
	var is_holding_blow: bool = Input.is_action_pressed("interact") and not (_tent != null and _tent.is_in_range(global_position.x))

	# ตรวจสอบว่าเป่าเข้าไปในระยะของกองไฟหรือไม่
	var blowing_into_fire: bool = _campfire != null and _campfire.is_in_range(sweep_target_x)

	if is_holding_blow:
		# มีการเป่าลมเกิดขึ้น: ถ้ามีใบไม้ให้เป่าใบไม้ด้วย ถ้าไม่มีให้เป่าลมเปล่า
		_update_blower_vfx(true, available >= 0.1)

		if blowing_into_fire:
			if available >= 0.1:
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
			if available >= 0.1:
				_leaf_grid.move_leaves(global_position.x, sweep_target_x, blow_amount)
	else:
		_update_blower_vfx(false, false)

	# อัปเดตข้อความ Prompt
	if blowing_into_fire:
		if available >= 0.1:
			_set_prompt("[Hold E] Blow into Fire")
		else:
			_set_prompt("")
	else:
		if available >= 0.1:
			_set_prompt("[Hold E] Blow %s" % arrow)
		else:
			_set_prompt("")


## การทำงานเมื่อใช้มือเปล่า (Hands)
func _handle_hands_interaction() -> void:
	var is_near_fire: bool = _campfire != null and _campfire.is_in_range(global_position.x)

	if is_near_fire:
		if carried_leaves > 0:
			var mult: float = _campfire.get_reward_multiplier()
			var est_reward: int = int(round(float(carried_leaves * _campfire.base_reward_per_leaf) * mult))
			_set_prompt("[E] Feed Fire (+%dG)" % est_reward)

			if Input.is_action_just_pressed("interact"):
				_play_action_animation("hands_gather", 0.35)
				var reward: int = _campfire.add_leaves(carried_leaves)
				coins += reward
				coins_changed.emit(coins)
				if _tent != null:
					_tent.update_label_display(upgrade_step, coins)
				carried_leaves = 0
				leaves_changed.emit(0, max_hand_capacity)
		else:
			_set_prompt("")
		return

	if _leaf_grid != null:
		var available_at_feet: float = _leaf_grid.get_leaf_count_at(global_position.x)
		var can_gather: bool = carried_leaves < max_hand_capacity and available_at_feet >= 1.0

		if carried_leaves >= max_hand_capacity:
			_set_prompt("Bag Full")
		elif can_gather:
			_set_prompt("[E] Pick Leaf")
			if Input.is_action_just_pressed("interact"):
				_play_action_animation("hands_gather", 0.35)
				var gathered: int = _leaf_grid.harvest_leaves(global_position.x, 1)
				if gathered > 0:
					carried_leaves += gathered
					leaves_changed.emit(carried_leaves, max_hand_capacity)
		else:
			_set_prompt("")


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
		_status_label.text = ""
		_status_label.visible = false


func _set_prompt(text: String) -> void:
	if _status_label != null:
		_status_label.text = ""
		_status_label.visible = false

	var cleaned: String = text.strip_edges()
	if cleaned.is_empty():
		prompt_updated.emit("", "", false)
		return

	# หากมีหลายบรรทัด ให้เลือกบรรทัดที่เป็น Action จริง (ไม่ใช่บรรทัดแสดงสถิติ)
	if cleaned.contains("\n"):
		var lines: PackedStringArray = cleaned.split("\n")
		var candidate: String = ""
		for i in range(lines.size() - 1, -1, -1):
			var l: String = lines[i].strip_edges()
			if not l.is_empty() and not l.begins_with("Coins:") and not l.begins_with("[Hands") and not l.begins_with("[Broom") and not l.begins_with("[Blower"):
				candidate = l
				break
		cleaned = candidate if not candidate.is_empty() else lines[lines.size() - 1].strip_edges()

	# หากเป็นข้อความปฏิเสธในวงเล็บ เช่น (No leaves...) หรือว่างเปล่า ให้ซ่อน prompt
	if cleaned.is_empty() or (cleaned.begins_with("(") and cleaned.ends_with(")")):
		prompt_updated.emit("", "", false)
		return

	var key_code: String = ""
	var action_text: String = cleaned

	# แยกปุ่มคีย์ลัดออกมา
	if cleaned.begins_with("[Hold E]"):
		key_code = "E"
		action_text = cleaned.substr(8).strip_edges()
	elif cleaned.begins_with("[E]"):
		key_code = "E"
		action_text = cleaned.substr(3).strip_edges()
	elif cleaned.begins_with("[Space]") or cleaned.begins_with("[SPACE]"):
		key_code = "SPACE"
		action_text = cleaned.substr(7).strip_edges()
	elif cleaned.contains("[Hold E]"):
		key_code = "E"
		var idx: int = cleaned.find("[Hold E]")
		action_text = cleaned.substr(idx + 8).strip_edges()
	elif cleaned.contains("[E]"):
		key_code = "E"
		var idx: int = cleaned.find("[E]")
		action_text = cleaned.substr(idx + 3).strip_edges()
	elif cleaned.contains("[Space]"):
		key_code = "SPACE"
		var idx: int = cleaned.find("[Space]")
		action_text = cleaned.substr(idx + 7).strip_edges()

	# ลบ tag ในวงเล็บเหลี่ยมส่วนเกินที่อาจติดมาข้างหน้า
	while action_text.begins_with("[") and action_text.contains("]"):
		var end_b: int = action_text.find("]")
		action_text = action_text.substr(end_b + 1).strip_edges()

	if action_text.is_empty() and key_code.is_empty():
		prompt_updated.emit("", "", false)
	else:
		prompt_updated.emit(key_code, action_text, true)


func _clear_prompt() -> void:
	_set_prompt("")


func _get_tool_anim_prefix() -> String:
	match current_tool:
		ToolType.HANDS:
			return "hands"
		ToolType.BROOM:
			return "broom"
		ToolType.BLOWER:
			return "blower"
	return "hands"


func _play_action_animation(anim_name: String, duration: float) -> void:
	_action_anim_timer = duration
	if _animated_sprite != null:
		_animated_sprite.play(anim_name)


## แสดงผลเอฟเฟกต์กวาดโดนใบไม้ (Sweep Hit Leaf Particles)
func _trigger_sweep_hit_vfx(leaves_count: float = 5.0) -> void:
	var dir_x: float = float(facing_direction)
	if _sweep_leaf_particles != null:
		_sweep_leaf_particles.position.x = 10.0 * dir_x
		_sweep_leaf_particles.direction = Vector2(dir_x, -0.3)
		# ปรับจำนวนเม็ดใบไม้ตามจำนวนที่กวาดจริง
		var particle_count: int = clampi(int(round(leaves_count * 1.5)), 8, 36)
		_sweep_leaf_particles.amount = particle_count
		_sweep_leaf_particles.restart()
		_sweep_leaf_particles.emitting = true

	if _sweep_wind_particles != null:
		_sweep_wind_particles.position.x = 10.0 * dir_x
		_sweep_wind_particles.direction = Vector2(dir_x, -0.2)
		_sweep_wind_particles.restart()
		_sweep_wind_particles.emitting = true


## แสดงผลเอฟเฟกต์กวาดลมเปล่า (Sweep Wind Particles)
func _trigger_sweep_wind_vfx() -> void:
	var dir_x: float = float(facing_direction)
	if _sweep_wind_particles != null:
		_sweep_wind_particles.position.x = 10.0 * dir_x
		_sweep_wind_particles.direction = Vector2(dir_x, -0.2)
		_sweep_wind_particles.restart()
		_sweep_wind_particles.emitting = true


## จัดการแสดงผล Particle ของเครื่องเป่าลม (Blower VFX)
func _update_blower_vfx(wind_active: bool, leaves_active: bool) -> void:
	var dir_x: float = float(facing_direction)

	if _blow_wind_particles != null:
		if wind_active:
			_blow_wind_particles.position.x = 10.0 * dir_x
			_blow_wind_particles.direction = Vector2(dir_x, 0.2)
			if not _blow_wind_particles.emitting:
				_blow_wind_particles.emitting = true
		else:
			if _blow_wind_particles.emitting:
				_blow_wind_particles.emitting = false

	if _blow_leaves_particles != null:
		if leaves_active:
			_blow_leaves_particles.position.x = 12.0 * dir_x
			_blow_leaves_particles.direction = Vector2(dir_x, -0.1)
			# ปรับปริมาณใบไม้ตามเลเวลของเครื่องเป่าลม (Lv.1: 14, Lv.2: 20, Lv.3: 28)
			var base_amount: int = 14 + (blower_level - 1) * 7
			if _blow_leaves_particles.amount != base_amount:
				_blow_leaves_particles.amount = base_amount
			if not _blow_leaves_particles.emitting:
				_blow_leaves_particles.emitting = true
		else:
			if _blow_leaves_particles.emitting:
				_blow_leaves_particles.emitting = false


func _update_animations(delta: float) -> void:
	if _animated_sprite == null:
		return

	# พลิกทิศทางตัวละครตามทิศทางการเดิน
	_animated_sprite.flip_h = (facing_direction < 0)

	# หากกำลังเล่นแอนิเมชัน One-shot อยู่ (เช่น ก้มหยิบ, กวาดไม้กวาด) ให้นับถอยหลังต่อจนจบ
	if _action_anim_timer > 0.0:
		_action_anim_timer = maxf(0.0, _action_anim_timer - delta)
		return

	# แอนิเมชันเป่าลมต่อเนื่องเมื่อกดปุ่มค้าง
	if current_tool == ToolType.BLOWER and Input.is_action_pressed("interact") and not (_tent != null and _tent.is_in_range(global_position.x)):
		if _animated_sprite.animation != &"blower_blow":
			_animated_sprite.play("blower_blow")
		return

	var prefix: String = _get_tool_anim_prefix()
	var target_anim: String = "%s_walk" % prefix if absf(velocity.x) > 5.0 else "%s_idle" % prefix
	if _animated_sprite.animation != StringName(target_anim):
		_animated_sprite.play(target_anim)

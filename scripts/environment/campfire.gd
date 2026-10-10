class_name Campfire
extends Node2D

## สัญญาณเมื่อมีการเติมใบไม้เข้ากองไฟ พร้อมจำนวนเงินรางวัลที่ได้รับ
signal leaves_added(amount: int, total_burned: int, reward_coins: int)

## สัญญาณเมื่อไฟลุกท่วมลามป่า เข้าสู่ End Game Climax
signal wildfire_started

## จำนวนใบไม้สะสมที่ถูกเติมเข้ากองไฟ
@export var total_leaves_burned: int = 0

## รางวัลเงินพื้นฐานต่อใบไม้ 1 ใบ
@export var base_reward_per_leaf: int = 10

## ระดับความร้อนและขนาดของไฟปัจจุบัน
@export var heat_level: float = 10.0

## ระดับความร้อนขั้นต่ำของกองไฟ
@export var min_heat_level: float = 10.0

## ขีดจำกัดความร้อนที่กองไฟจะลามไหม้ทั้งป่า (End Game Threshold)
@export var wildfire_threshold: float = 200.0

## ค่าความร้อนที่เพิ่มขึ้นต่อใบไม้ 1 ใบ
@export var heat_per_leaf: float = 1.5

## ค่าสัมประสิทธิ์การมอดพื้นฐานตามเวลา
@export var decay_base: float = 1.0

## อัตราเร่งของเวลายกกำลัง (Exponential: ยิ่งเวลาผ่านไปนาน ยิ่งมอดเร็วขึ้นแบบทวีคูณ)
@export var time_decay_exponent: float = 2.2

## รัศมีการตรวจจับระยะมีผลของกองไฟ (Pixel)
@export var interact_radius: float = 65.0

## เวลาที่นับตั้งแต่เริ่มมีการเติมใบไม้รอบปัจจุบัน
var burn_elapsed_time: float = 0.0

## สถานะการเริ่มนับเวลาของการสุมไฟ
var is_burning: bool = false

## สถานะไฟลามไหม้ทั้งป่า (End Game)
var is_wildfire: bool = false

@onready var _fire_core: ColorRect = $FireCore
@onready var _label: Label = $Label


func _ready() -> void:
	if _fire_core != null:
		_fire_core.pivot_offset = Vector2(12.0, 30.0)
	_update_visuals()


func _physics_process(delta: float) -> void:
	if is_wildfire:
		# ในสถานะไฟลามทั้งป่า ให้ขยายเปลวเพลิงยักษ์โหมกระหน่ำอย่างต่อเนื่อง
		heat_level = minf(1000.0, heat_level + 200.0 * delta)
		_update_visuals()
		return

	# อัตราการลดขนาดของไฟจะขึ้นอยู่กับระยะเวลาที่ผ่านไปแบบ Exponential
	if is_burning:
		burn_elapsed_time += delta
		var time_factor: float = pow(1.0 + burn_elapsed_time, time_decay_exponent)
		var time_decay: float = decay_base * time_factor * delta
		heat_level = maxf(min_heat_level, heat_level - time_decay)

		# หากมอดลงมาจนถึงระดับปกติ ให้รีเซ็ตเวลาเพื่อเริ่มการนับรอบใหม่
		if heat_level <= min_heat_level:
			heat_level = min_heat_level
			burn_elapsed_time = 0.0
			is_burning = false

		_update_visuals()


## คำนวณตัวคูณรางวัลจากขนาด/ความร้อนของกองไฟ
func get_reward_multiplier() -> float:
	var extra_heat: float = maxf(0.0, heat_level - min_heat_level)
	return 1.0 + (extra_heat * 0.05)


## นำใบไม้มาสุมกองไฟ และเริ่มทริกเกอร์นับเวลา
func add_leaves(amount: int) -> int:
	if amount <= 0 or is_wildfire:
		return 0

	# เริ่มทริกเกอร์นับเวลาเมื่อมีการเติมใบไม้รอบใหม่
	if not is_burning:
		is_burning = true
		burn_elapsed_time = 0.0

	var current_multiplier: float = get_reward_multiplier()
	var earned_reward: int = int(round(float(amount * base_reward_per_leaf) * current_multiplier))

	total_leaves_burned += amount
	heat_level += float(amount) * heat_per_leaf

	# ตรวจสอบเงื่อนไขจบเกม: หากสุมไฟได้แรงพอในเวลาอันสั้นจนทะลุเพดาน
	if heat_level >= wildfire_threshold and not is_wildfire:
		trigger_wildfire()

	leaves_added.emit(amount, total_leaves_burned, earned_reward)
	_update_visuals()
	return earned_reward


## สั่งเปิดฉากไฟลามไหม้ทั้งป่า (Wildfire Climax)
func trigger_wildfire() -> void:
	is_wildfire = true
	wildfire_started.emit()
	if _label != null:
		_label.text = "WILDFIRE!\nSPREADING TO FOREST!"
		_label.modulate = Color(1.0, 0.2, 0.1, 1.0)


## ตรวจสอบว่าตัวละครอยู่ในระยะของกองไฟหรือไม่
func is_in_range(target_x: float) -> bool:
	return absf(global_position.x - target_x) <= interact_radius


## อัปเดตขนาดและข้อความของกองไฟตามปริมาณเชื้อเพลิงและระยะเวลา
func _update_visuals() -> void:
	if _fire_core != null:
		var extra: float = heat_level - min_heat_level
		# สเกลไฟจะขยายตั้งแต่ 1.0x จนถึง 15.0x เมื่อเกิด Wildfire
		var max_scale: float = 16.0 if is_wildfire else 4.0
		var scale_factor: float = clampf(1.0 + (extra * 0.04), 1.0, max_scale)
		_fire_core.scale = Vector2(scale_factor, scale_factor)

	if _label != null and not is_wildfire:
		var mult: float = get_reward_multiplier()
		if is_burning:
			_label.text = "Campfire (x%.1f)\nTime: %.1fs\nBurned: %d" % [mult, burn_elapsed_time, total_leaves_burned]
		else:
			_label.text = "Campfire (x1.0)\nReady\nBurned: %d" % total_leaves_burned

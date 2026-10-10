class_name LeafGrid
extends Node2D

## ความกว้างของแต่ละช่อง Grid (Pixel)
@export var cell_size: float = 80.0

## จำนวนช่อง Grid ทั้งหมด (ครอบคลุมความยาว Platform 3500px)
@export var total_cells: int = 45

## อัตราการร่วงของใบไม้ต่อวินาทีในบริเวณใต้ต้นไม้
@export var fall_rate: float = 1.0

## อัตราการย่อยสลายแบบเส้นตรงต่อวินาที (ลดน้อยกว่าอัตราการร่วงของต้นไม้เล็กน้อย)
@export var linear_decay_rate: float = 0.25

## จำนวนใบไม้ขั้นต่ำที่จะเริ่มย่อยสลาย (จะไม่ลดลงจนเหลือ 0)
@export var min_decay_threshold: float = 3.0

## จำนวนใบไม้สูงสุดในแต่ละช่อง Grid (จะไม่ร่วงเพิ่มเมื่อถึงขีดจำกัดนี้)
@export var max_leaves_per_cell: float = 20

## อาร์เรย์เก็บจำนวนใบไม้ในแต่ละช่อง Grid
var cells: Array[float] = []

## กำหนดว่าช่องไหนอยู่ใต้ร่มเงาต้นไม้
var is_tree_zone: Array[bool] = []

## ตัวจับเวลาจำกัดการวาดใหม่ (Redraw) เพื่อประสิทธิภาพ
var _redraw_timer: float = 0.0


func _ready() -> void:
	cells.resize(total_cells)
	is_tree_zone.resize(total_cells)
	
	for i: int in range(total_cells):
		cells[i] = 0.0
		is_tree_zone[i] = false
		
	_initialize_tree_zones()


func _physics_process(delta: float) -> void:
	_simulate_accumulation(delta)
	_simulate_linear_decay(delta)
	
	# อัปเดตการแสดงผลบนพื้นดินทุก ๆ 0.05 วินาที
	_redraw_timer += delta
	if _redraw_timer >= 0.05:
		_redraw_timer = 0.0
		queue_redraw()


## กำหนดพื้นที่ใต้ต้นไม้ (ดึงตำแหน่งต้นไม้จริงในฉาก และกันพื้นที่แคมป์ไฟออก)
func _initialize_tree_zones() -> void:
	var tree_nodes: Array[Node] = get_tree().get_nodes_in_group("trees")
	var tree_x_positions: Array[float] = []

	if not tree_nodes.is_empty():
		for node: Node in tree_nodes:
			if node is Node2D:
				tree_x_positions.append(node.global_position.x)
	else:
		# Fallback ตำแหน่งต้นไม้เริ่มต้น (Tree1 เริ่มต้นที่ X=450)
		tree_x_positions = [
			450.0, 750.0, 1100.0, 1450.0, 1850.0, 2250.0, 2650.0, 3050.0, 3350.0
		]

	var tree_radius: float = 120.0

	for tree_x: float in tree_x_positions:
		var start_idx: int = clampi(int((tree_x - tree_radius) / cell_size), 0, total_cells - 1)
		var end_idx: int = clampi(int((tree_x + tree_radius) / cell_size), 0, total_cells - 1)
		for idx: int in range(start_idx, end_idx + 1):
			is_tree_zone[idx] = true

	# รับประกันว่าพื้นที่ลานแคมป์ไฟและเต็นท์ (X < 280px) จะไม่มีใบไม้ร่วงทับ
	var safe_clearing_idx: int = int(280.0 / cell_size)
	for i: int in range(safe_clearing_idx):
		is_tree_zone[i] = false


## 1. การสะสมของใบไม้ที่ร่วงใต้ต้นไม้ (มีขีดจำกัดสูงสุด ไม่ร่วงเพิ่มหากเต็มโควต้า)
func _simulate_accumulation(delta: float) -> void:
	for i: int in range(total_cells):
		if is_tree_zone[i] and cells[i] < max_leaves_per_cell:
			cells[i] = minf(max_leaves_per_cell, cells[i] + fall_rate * delta)


## 2. การย่อยสลายแบบเส้นตรง (Linear) เริ่มลดเมื่อเกินค่าขั้นต่ำ และไม่ลดจนเหลือ 0
func _simulate_linear_decay(delta: float) -> void:
	for i: int in range(total_cells):
		if cells[i] > min_decay_threshold:
			cells[i] = maxf(min_decay_threshold, cells[i] - linear_decay_rate * delta)


## แปลงพิกัด X ของโลกเป็น Index ของช่อง Grid
func get_cell_index(world_x: float) -> int:
	return clampi(int(world_x / cell_size), 0, total_cells - 1)


## ตรวจสอบจำนวนใบไม้ในพิกัดที่ระบุ
func get_leaf_count_at(world_x: float) -> float:
	var idx: int = get_cell_index(world_x)
	return cells[idx]


## หยิบใบไม้ออกจากตำแหน่งพิกัด X
func harvest_leaves(world_x: float, amount_requested: int) -> int:
	var idx: int = get_cell_index(world_x)
	var available: int = int(cells[idx])
	var harvested: int = mini(amount_requested, available)
	cells[idx] -= float(harvested)
	queue_redraw()
	return harvested


## หยิบใบไม้แบบทศนิยม (สำหรับเครื่องมือเช่นไม้กวาด)
func harvest_leaves_float(world_x: float, max_amount: float) -> float:
	var idx: int = get_cell_index(world_x)
	var available: float = cells[idx]
	var harvested: float = minf(available, max_amount)
	cells[idx] -= harvested
	queue_redraw()
	return harvested


## ขยับ/กวาดใบไม้จากตำแหน่งหนึ่งไปยังอีกตำแหน่งหนึ่ง
func move_leaves(from_x: float, to_x: float, max_amount: float = 5.0) -> float:
	var from_idx: int = get_cell_index(from_x)
	var to_idx: int = get_cell_index(to_x)
	if from_idx == to_idx:
		return 0.0

	var available: float = cells[from_idx]
	var moved: float = minf(available, max_amount)
	if moved > 0.0:
		cells[from_idx] -= moved
		cells[to_idx] += moved
		queue_redraw()

	return moved


## วาดแถบสีและกองใบไม้บนพื้นดินตามความหนาแน่นของใบไม้ (ปรับสเกลรองรับ 0 - 300 ใบ)
func _draw() -> void:
	for i: int in range(total_cells):
		var count: float = cells[i]
		if count < 0.5:
			continue

		var x_pos: float = float(i) * cell_size
		var ground_y: float = 0.0 # Origin ของโหนดนี้อยู่ที่ระดับพื้นดิน

		# สเกลอัตราส่วนความสูงตามช่วง 0 ถึง 300 ใบ (ใช้ Curve 0.8 เพื่อให้กองเล็ก 1-15 ใบก็ยังสังเกตเห็นได้)
		var ratio: float = clampf(count / 300.0, 0.0, 1.0)
		var pile_height: float = lerpf(3.0, 48.0, pow(ratio, 0.8))

		# คำนวณสีตามระดับปริมาณ 0 - 300 ใบ
		var fill_color: Color
		if count < 15.0:
			# 0 - 15 ใบ: สีเหลืองทองระเรื่อ (เศษใบไม้ประปราย)
			var alpha: float = clampf(count / 15.0, 0.35, 0.65)
			fill_color = Color(0.92, 0.78, 0.25, alpha)
		elif count < 60.0:
			# 15 - 60 ใบ: สีส้มอบอุ่น (เริ่มเป็นกองย่อม)
			var t: float = (count - 15.0) / 45.0
			fill_color = Color(0.96, 0.52, 0.12, lerpf(0.65, 0.85, t))
		elif count < 150.0:
			# 60 - 150 ใบ: สีแดงส้ม Autumn Amber (กองขนาดกลาง)
			var t: float = (count - 60.0) / 90.0
			fill_color = Color(0.88, 0.28, 0.12, lerpf(0.85, 0.95, t))
		else:
			# 150 - 300+ ใบ: สีแดงเข้ม Crimson / Burgundy (กองใหญ่หนาแน่นมาก)
			var t: float = clampf((count - 150.0) / 150.0, 0.0, 1.0)
			fill_color = Color(0.68, 0.12, 0.10, lerpf(0.95, 1.0, t))

		# วาดแท่งแทนความหนาแน่นของกองใบไม้บนพื้นดิน
		draw_rect(Rect2(x_pos + 1.0, ground_y - pile_height, cell_size - 2.0, pile_height + 2.0), fill_color)

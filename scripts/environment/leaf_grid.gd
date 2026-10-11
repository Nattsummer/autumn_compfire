class_name LeafGrid
extends Node2D

## ความกว้างของแต่ละช่อง Grid (Pixel)
@export var cell_size: float = 40

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

## สไปรต์กองใบไม้ 5 ระดับ (Tiers 0 - 4)
const TIER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/environment/leaf_piles/pile_tier_0.png"),
	preload("res://assets/environment/leaf_piles/pile_tier_1.png"),
	preload("res://assets/environment/leaf_piles/pile_tier_2.png"),
	preload("res://assets/environment/leaf_piles/pile_tier_3.png"),
	preload("res://assets/environment/leaf_piles/pile_tier_4.png")
]


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


## วาดกองใบไม้บนพื้นดินตามระดับ Tier ของจำนวนใบไม้ (สเปก 5 Tiers ที่สเกล 1x)
func _draw() -> void:
	for i: int in range(total_cells):
		var count: float = cells[i]
		if count < 0.5:
			continue

		var x_pos: float = float(i) * cell_size

		# เลือก Tier ตามสเปกใน ASSET_REQUIREMENTS.md:
		# Tier 0: 1 - 5 ใบ
		# Tier 1: 6 - 20 ใบ
		# Tier 2: 21 - 60 ใบ
		# Tier 3: 61 - 150 ใบ
		# Tier 4: 151 - 300+ ใบ
		var tex: Texture2D = null
		if count < 6.0:
			tex = TIER_TEXTURES[0]
		elif count < 21.0:
			tex = TIER_TEXTURES[1]
		elif count < 61.0:
			tex = TIER_TEXTURES[2]
		elif count < 151.0:
			tex = TIER_TEXTURES[3]
		else:
			tex = TIER_TEXTURES[4]

		if tex != null:
			# จัดวางฐานกองใบไม้ขนาด 64x64 สเกล 1x กึ่งกลางช่องแนบผิวดิน (y = 0)
			var offset_x: float = (cell_size - 64.0) * 0.5
			var tex_rect: Rect2 = Rect2(x_pos + offset_x, -48.0, 64.0, 64.0)
			draw_texture_rect(tex, tex_rect, false)

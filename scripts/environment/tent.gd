class_name Tent
extends Node2D

## ส่งสัญญาณเมื่อมีการซื้อการอัพเกรดสำเร็จ
signal upgrade_purchased(step: int, title: String, cost: int)

## รัศมีการตรวจจับระยะมีผลของเต็นท์สำหรับอัพเกรด
@export var interact_radius: float = 65.0

## ลำดับค่าสเตตัสของมือ (จำนวนใบไม้ที่เก็บได้ตามเลเวล 1, 2, 3)
@export var hands_capacities: Array[int] = [2, 5, 10]

## ลำดับค่าสเตตัสของไม้กวาด (จำนวนใบไม้ที่กวาดได้ต่อครั้งตามเลเวล 1, 2, 3)
@export var broom_sweeps: Array[float] = [5.0, 15.0, 35.0]

## ลำดับค่าคูลดาวน์ของไม้กวาด (วินาทีตามเลเวล 1, 2, 3)
@export var broom_cooldowns: Array[float] = [0.60, 0.40, 0.25]

## ลำดับอัตราการเป่าของเครื่องเป่าลม (ใบไม้ต่อวินาทีตามเลเวล 1, 2, 3)
@export var blower_rates: Array[float] = [30.0, 80.0, 200.0]

## ราคาอัพเกรดแบบเชิงเส้น (Linear 8 ขั้น: Hands Lv2, Hands Lv3, Unlock Broom Lv1, Broom Lv2, Broom Lv3, Unlock Blower Lv1, Blower Lv2, Blower Lv3)
@export var upgrade_costs: Array[int] = [30, 80, 180, 400, 800, 1500, 3000, 5500]

@onready var _label: Label = $Label
@onready var _skill_tree_ui: SkillTreeUI = $SkillTreeUI


func _ready() -> void:
	if _label != null:
		_label.text = "Tent [Upgrades]"


## ตรวจสอบว่าผู้เล่นอยู่ในระยะของเต็นท์หรือไม่
func is_in_range(target_x: float) -> bool:
	return absf(global_position.x - target_x) <= interact_radius


## เปิดหน้าต่าง Skill Tree
func open_skill_tree(player: Player) -> void:
	if _skill_tree_ui != null:
		_skill_tree_ui.open(player, self)


## ปิดหน้าต่าง Skill Tree
func close_skill_tree() -> void:
	if _skill_tree_ui != null:
		_skill_tree_ui.close()


## ตรวจสอบว่าหน้าต่าง Skill Tree กำลังเปิดอยู่หรือไม่
func is_skill_tree_open() -> bool:
	return _skill_tree_ui != null and _skill_tree_ui.visible


## คืนค่าจำนวนขั้นการอัพเกรดทั้งหมด
func get_total_steps() -> int:
	return upgrade_costs.size()


## คืนค่าข้อมูลของการอัพเกรดในขั้นที่กำหนด
func get_upgrade_info(step: int) -> Dictionary:
	match step:
		0:
			return {
				"valid": true,
				"title": "Hands Lv.2",
				"tool": Player.ToolType.HANDS,
				"level": 2,
				"cost": upgrade_costs[0],
				"desc": "+%d Leaf Cap (%d total)" % [hands_capacities[1] - hands_capacities[0], hands_capacities[1]]
			}
		1:
			return {
				"valid": true,
				"title": "Hands Lv.3",
				"tool": Player.ToolType.HANDS,
				"level": 3,
				"cost": upgrade_costs[1],
				"desc": "+%d Leaf Cap (%d total - Max)" % [hands_capacities[2] - hands_capacities[1], hands_capacities[2]]
			}
		2:
			return {
				"valid": true,
				"title": "Unlock Broom Lv.1",
				"tool": Player.ToolType.BROOM,
				"level": 1,
				"cost": upgrade_costs[2],
				"desc": "Sweep: %.0f | CD: %.2fs" % [broom_sweeps[0], broom_cooldowns[0]]
			}
		3:
			return {
				"valid": true,
				"title": "Broom Lv.2",
				"tool": Player.ToolType.BROOM,
				"level": 2,
				"cost": upgrade_costs[3],
				"desc": "Sweep: %.0f | CD: %.2fs" % [broom_sweeps[1], broom_cooldowns[1]]
			}
		4:
			return {
				"valid": true,
				"title": "Broom Lv.3",
				"tool": Player.ToolType.BROOM,
				"level": 3,
				"cost": upgrade_costs[4],
				"desc": "Sweep: %.0f | CD: %.2fs (Max)" % [broom_sweeps[2], broom_cooldowns[2]]
			}
		5:
			return {
				"valid": true,
				"title": "Unlock Blower Lv.1",
				"tool": Player.ToolType.BLOWER,
				"level": 1,
				"cost": upgrade_costs[5],
				"desc": "Blow Rate: %.0f/s" % blower_rates[0]
			}
		6:
			return {
				"valid": true,
				"title": "Blower Lv.2",
				"tool": Player.ToolType.BLOWER,
				"level": 2,
				"cost": upgrade_costs[6],
				"desc": "Blow Rate: %.0f/s" % blower_rates[1]
			}
		7:
			return {
				"valid": true,
				"title": "Blower Lv.3",
				"tool": Player.ToolType.BLOWER,
				"level": 3,
				"cost": upgrade_costs[7],
				"desc": "Blow Rate: %.0f/s (Max)" % blower_rates[2]
			}
		_:
			return {"valid": false}


## อัปเดตข้อความบนป้ายเต็นท์ให้สอดคล้องกับสถานะ
func update_label_display(step: int, player_coins: int) -> void:
	if _label == null:
		return
	
	if step >= get_total_steps():
		_label.text = "Tent [Maxed]"
		return
	
	var info: Dictionary = get_upgrade_info(step)
	if info.get("valid", false):
		var cost: int = int(info["cost"])
		if player_coins >= cost:
			_label.text = "Tent [Upgrade!]\n%s (%dG)" % [String(info["title"]), cost]
		else:
			_label.text = "Tent\n%s (%dG)" % [String(info["title"]), cost]


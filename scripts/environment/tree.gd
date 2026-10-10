class_name ForestTree
extends Node2D

@onready var _trunk: ColorRect = $Trunk
@onready var _foliage_bottom: Polygon2D = $FoliageBottom
@onready var _foliage_top: Polygon2D = $FoliageTop
@onready var _label: Label = $Label

## บันทึกสถานะว่าต้นไม้ถูกไฟลามไหม้แล้วหรือยัง
var is_burning: bool = false


## จุดไฟเผาต้นไม้เมื่อไฟจากกองไฟลามมาถึง (End Game Sequence)
func ignite() -> void:
	if is_burning:
		return
	is_burning = true

	# เปลี่ยนสีต้นไม้ให้กลายเป็นไฟลุกโชน
	if _foliage_bottom != null:
		_foliage_bottom.color = Color(0.98, 0.45, 0.1, 1.0)
	if _foliage_top != null:
		_foliage_top.color = Color(1.0, 0.85, 0.25, 1.0)
	if _trunk != null:
		_trunk.color = Color(0.18, 0.1, 0.08, 1.0)

	if _label != null:
		_label.text = "BURNING!"
		_label.modulate = Color(1.0, 0.4, 0.1, 1.0)

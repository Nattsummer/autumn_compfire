class_name ForestTree
extends Node2D

## รูปแบบทรงต้นไม้ (0 ถึง 4 สำหรับ 5 variants ตามคอลัมน์ใน Sheet, ค่า -1 คือสุ่ม/กระจายตามลำดับต้นไม้)
@export var variant: int = -1

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _falling_leaves: CPUParticles2D = $FallingLeaves
@onready var _label: Label = $Label

## บันทึกสถานะว่าต้นไม้ถูกไฟลามไหม้แล้วหรือยัง
var is_burning: bool = false


func _ready() -> void:
	# หากไม่ได้กำหนด variant มาเจาะจง ให้กำหนดตามลำดับ Index ในฉาก (0 ถึง 4)
	if variant < 0:
		variant = get_index() % 5
	else:
		variant = clampi(variant, 0, 4)

	if _animated_sprite != null:
		var anim_name: String = "variant_%d" % variant
		_animated_sprite.play(anim_name)
		# กระจายเฟรมเริ่มต้นเพื่อไม่ให้ต้นไม้ทุกต้นพริ้วไหวพร้อมกันเป็นระนาบเดียว
		_animated_sprite.frame = (get_index() * 2) % 5

	if _falling_leaves != null:
		# สลับจังหวะการร่วงของใบไม้ในแต่ละต้นให้เป็นธรรมชาติ
		_falling_leaves.preprocess = 1.0 + float(get_index() % 4) * 0.6
		_falling_leaves.restart()


## จุดไฟเผาต้นไม้เมื่อไฟจากกองไฟลามมาถึง (End Game Sequence)
func ignite() -> void:
	if is_burning:
		return
	is_burning = true

	# เปลี่ยนสีต้นไม้ให้กลายเป็นไฟลุกโชนแล้วค่อย ๆ กลายเป็นเถ้าถ่าน
	if _animated_sprite != null:
		var tween: Tween = create_tween()
		tween.tween_property(_animated_sprite, "modulate", Color(2.0, 0.5, 0.1, 1.0), 0.4)
		tween.tween_property(_animated_sprite, "modulate", Color(0.3, 0.12, 0.08, 0.9), 2.5)

	# เมื่อต้นไม้ติดไฟ ให้เปลี่ยนใบไม้ร่วงเป็นสะเก็ดไฟแล้วหยุดการร่วง
	if _falling_leaves != null:
		var leaf_tween: Tween = create_tween()
		leaf_tween.tween_property(_falling_leaves, "modulate", Color(2.0, 0.4, 0.1, 1.0), 0.5)
		leaf_tween.tween_callback(func(): _falling_leaves.emitting = false)

	if _label != null:
		_label.text = "BURNING!"
		_label.modulate = Color(1.0, 0.4, 0.1, 1.0)

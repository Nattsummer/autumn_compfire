class_name ForegroundBushGrass
extends Parallax2D

## ความเร็วและการโยกพริ้วไหวของยอดหญ้าหน้ากล้องตามลม
@export var wind_sway_enabled: bool = true
@export var sway_speed: float = 2.5
@export var sway_degrees: float = 2.0

## สลับเปิด/ปิดกิ่งไม้ห้อยด้านบนขอบจอ (Overhead Foliage)
@export var show_overhead: bool = true

@onready var _grass_sprite: Sprite2D = $GrassSprite
@onready var _overhead_sprite: Sprite2D = $OverheadSprite

var _time: float = 0.0


func _ready() -> void:
	if _overhead_sprite != null:
		_overhead_sprite.visible = show_overhead


func _process(delta: float) -> void:
	if not wind_sway_enabled:
		return
	
	_time += delta * sway_speed
	var sway_rad: float = deg_to_rad(sin(_time) * sway_degrees)
	
	if _grass_sprite != null:
		_grass_sprite.skew = sway_rad
	if _overhead_sprite != null and show_overhead:
		_overhead_sprite.skew = -sway_rad * 0.6

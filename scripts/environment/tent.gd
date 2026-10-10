class_name Tent
extends Node2D

## รัศมีการตรวจจับระยะมีผลของเต็นท์สำหรับเปลี่ยนไอเทม
@export var interact_radius: float = 65.0

@onready var _label: Label = $Label


## ตรวจสอบว่าผู้เล่นอยู่ในระยะของเต็นท์หรือไม่
func is_in_range(target_x: float) -> bool:
	return absf(global_position.x - target_x) <= interact_radius

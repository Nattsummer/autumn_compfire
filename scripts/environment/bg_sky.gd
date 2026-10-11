class_name BackgroundSky
extends Node2D

## ความเร็วลมพัดเมฆลอยตามสายลมออทัมน์ (Pixel / วินาที)
@export var cloud_wind_speed: float = 6.0

## ตัวคูณ Parallax เมื่อผู้เล่นเดิน (ตามสเปก ASSET_REQUIREMENTS: 0.2x - 0.4x)
@export var mountain_parallax: float = 0.25
@export var cloud_parallax: float = 0.08
@export var sky_parallax: float = 0.0

@onready var _sky_layer: Parallax2D = $SkyLayer
@onready var _cloud_layer: Parallax2D = $CloudLayer
@onready var _mountain_layer: Parallax2D = $MountainLayer

@onready var _sky_sprite: Sprite2D = $SkyLayer/Sprite2D
@onready var _cloud_sprite: Sprite2D = $CloudLayer/Sprite2D
@onready var _mountain_sprite: Sprite2D = $MountainLayer/Sprite2D


func _ready() -> void:
	if _sky_layer != null:
		_sky_layer.scroll_scale = Vector2(sky_parallax, 1.0)
	if _cloud_layer != null:
		_cloud_layer.scroll_scale = Vector2(cloud_parallax, 1.0)
		_cloud_layer.autoscroll = Vector2(cloud_wind_speed, 0.0)
	if _mountain_layer != null:
		_mountain_layer.scroll_scale = Vector2(mountain_parallax, 1.0)


## เปลี่ยนโทนสีท้องฟ้า เมฆ และทิวเขาให้กลายเป็นสีเพลิงเมื่อเข้าสู่ Climax Wildfire
func on_wildfire_started() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	if _sky_sprite != null:
		tween.tween_property(_sky_sprite, "modulate", Color(1.6, 0.45, 0.15, 1.0), 3.0)
	if _cloud_sprite != null:
		tween.tween_property(_cloud_sprite, "modulate", Color(1.3, 0.35, 0.1, 0.85), 3.0)
	if _mountain_sprite != null:
		tween.tween_property(_mountain_sprite, "modulate", Color(1.4, 0.4, 0.15, 1.0), 3.0)

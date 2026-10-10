class_name MainLevel
extends Node2D

@onready var _campfire: Campfire = $Environment/CampSite/Campfire
@onready var _forest_trees: Node2D = $Environment/ForestTrees
@onready var _sky_bg: ColorRect = $SkyBackground
@onready var _end_game_layer: CanvasLayer = $EndGameUI


func _ready() -> void:
	if _campfire != null:
		_campfire.wildfire_started.connect(_on_wildfire_started)


## เมื่อกองไฟขยายขนาดใหญ่จนเริ่มลามป่า
func _on_wildfire_started() -> void:
	# 1. ปรับสีท้องฟ้าให้เป็นสีส้มเพลิงลุกโชนอย่างน่าเกรงขาม
	if _sky_bg != null:
		var tween: Tween = create_tween()
		tween.tween_property(_sky_bg, "color", Color(0.78, 0.22, 0.08, 1.0), 3.0)

	# 2. ไฟลามไปติดต้นไม้ทุกต้นตามลำดับจากซ้ายไปขวา
	if _forest_trees != null:
		var trees: Array[Node] = _forest_trees.get_children()
		for i: int in range(trees.size()):
			var tree_node: ForestTree = trees[i] as ForestTree
			if tree_node != null:
				# ลามทีละต้นห่างกัน 0.35 วินาที
				var delay: float = float(i) * 0.35
				get_tree().create_timer(delay).timeout.connect(tree_node.ignite)

	# 3. แสดงหน้าจอ End Game สรุปผล
	get_tree().create_timer(4.0).timeout.connect(_show_end_game_screen)


func _show_end_game_screen() -> void:
	if _end_game_layer != null:
		_end_game_layer.visible = true

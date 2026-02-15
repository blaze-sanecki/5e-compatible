class_name EdgeWallRenderer
extends Node2D

## Draws thin lines at edge-wall positions.
##
## Renders NORTH and EAST edges per cell (skipping SOUTH/WEST to avoid
## double-drawing reciprocals). Covers both interior walls and perimeter walls.

var _edge_walls: EdgeWallMap
var _floor_layer: TileMapLayer
var _wall_color: Color = Color(0.15, 0.12, 0.1)


func setup(ew: EdgeWallMap, fl: TileMapLayer) -> void:
	_edge_walls = ew
	_floor_layer = fl
	queue_redraw()


func _draw() -> void:
	if _edge_walls == null or _floor_layer == null or _floor_layer.tile_set == null:
		return

	var tile_size: Vector2i = _floor_layer.tile_set.tile_size
	var thickness: float = tile_size.x / 4.0
	var half_t: float = thickness / 2.0
	var half_w: float = tile_size.x / 2.0
	var half_h: float = tile_size.y / 2.0

	var walls: Dictionary = _edge_walls.get_wall_data()
	for cell: Vector2i in walls:
		var bitmask: int = walls[cell]
		var center: Vector2 = _floor_layer.map_to_local(cell)

		# Only draw NORTH and EAST edges to avoid double-drawing reciprocals.

		if bitmask & EdgeWallMap.NORTH:
			draw_rect(Rect2(
				center.x - half_w, center.y - half_h - half_t,
				tile_size.x, thickness
			), _wall_color)

		if bitmask & EdgeWallMap.EAST:
			draw_rect(Rect2(
				center.x + half_w - half_t, center.y - half_h,
				thickness, tile_size.y
			), _wall_color)

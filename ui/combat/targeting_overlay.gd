class_name TargetingOverlay
extends Node2D

## Draws colored cell highlights on the grid for movement range, attack range,
## and AoE placement during combat.

## Reference to the floor layer for coordinate conversion.
var floor_layer: TileMapLayer

## Currently highlighted cells by category.
var _movement_cells: Array[Vector2i] = []
var _target_cells: Array[Vector2i] = []
var _aoe_cells: Array[Vector2i] = []

## Colors for each overlay type.
var movement_color: Color = Color(0.2, 0.5, 1.0, 0.25)
var target_color: Color = Color(1.0, 0.2, 0.2, 0.35)
var aoe_color: Color = Color(1.0, 0.6, 0.1, 0.3)

## Cell size in pixels (matched to tilemap).
var _cell_size: Vector2 = Vector2(32, 32)


func setup(p_floor_layer: TileMapLayer) -> void:
	floor_layer = p_floor_layer
	if floor_layer and floor_layer.tile_set:
		_cell_size = Vector2(floor_layer.tile_set.tile_size)


## Show movement range cells.
func show_movement(cells: Array[Vector2i]) -> void:
	_movement_cells = cells
	_target_cells.clear()
	_aoe_cells.clear()
	queue_redraw()


## Show attack target cells.
func show_targets(cells: Array[Vector2i]) -> void:
	_target_cells = cells
	_movement_cells.clear()
	_aoe_cells.clear()
	queue_redraw()


## Show AoE cells.
func show_aoe(cells: Array[Vector2i]) -> void:
	_aoe_cells = cells
	queue_redraw()


## Clear all overlays.
func clear() -> void:
	_movement_cells.clear()
	_target_cells.clear()
	_aoe_cells.clear()
	queue_redraw()


func _draw() -> void:
	if floor_layer == null:
		return

	var half: Vector2 = _cell_size / 2.0

	# Draw movement cells.
	for cell in _movement_cells:
		var pos: Vector2 = floor_layer.map_to_local(cell) - half
		draw_rect(Rect2(pos, _cell_size), movement_color)
		# Draw border.
		draw_rect(Rect2(pos, _cell_size), Color(0.3, 0.6, 1.0, 0.5), false, 1.0)

	# Draw target cells.
	for cell in _target_cells:
		var pos: Vector2 = floor_layer.map_to_local(cell) - half
		draw_rect(Rect2(pos, _cell_size), target_color)
		draw_rect(Rect2(pos, _cell_size), Color(1.0, 0.3, 0.3, 0.7), false, 2.0)

	# Draw AoE cells.
	for cell in _aoe_cells:
		var pos: Vector2 = floor_layer.map_to_local(cell) - half
		draw_rect(Rect2(pos, _cell_size), aoe_color)
		draw_rect(Rect2(pos, _cell_size), Color(1.0, 0.7, 0.2, 0.6), false, 1.5)

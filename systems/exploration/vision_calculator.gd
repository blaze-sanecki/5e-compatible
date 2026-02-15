class_name VisionCalculator
extends RefCounted

## Calculates line-of-sight visibility for both hex and grid maps.
##
## Uses cube_line for hex maps and Bresenham's line for grid maps.
## Walls and out-of-bounds cells block vision.

# ---------------------------------------------------------------------------
# Grid vision (Bresenham + wall check)
# ---------------------------------------------------------------------------

## Calculate visible cells from a center on a square grid.
##
## Returns all cells within [code]radius[/code] that have unblocked LoS.
## Walls on the wall_layer block vision beyond them.
func calculate_grid_vision(
	center: Vector2i,
	radius: int,
	floor_layer: TileMapLayer,
	wall_layer: TileMapLayer
) -> Array[Vector2i]:
	var visible: Array[Vector2i] = [center]

	# Cast rays to the perimeter of the visibility square.
	for x in range(center.x - radius, center.x + radius + 1):
		_cast_grid_ray(center, Vector2i(x, center.y - radius), floor_layer, wall_layer, visible)
		_cast_grid_ray(center, Vector2i(x, center.y + radius), floor_layer, wall_layer, visible)
	for y in range(center.y - radius + 1, center.y + radius):
		_cast_grid_ray(center, Vector2i(center.x - radius, y), floor_layer, wall_layer, visible)
		_cast_grid_ray(center, Vector2i(center.x + radius, y), floor_layer, wall_layer, visible)

	return visible


func _cast_grid_ray(
	from: Vector2i,
	to: Vector2i,
	floor_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	visible: Array[Vector2i]
) -> void:
	var line: Array[Vector2i] = _bresenham_line(from, to)
	for cell in line:
		# Out of map = stop.
		if floor_layer.get_cell_source_id(cell) == -1:
			break

		if cell not in visible:
			visible.append(cell)

		# Wall blocks further vision (but the wall itself is visible).
		if wall_layer.get_cell_source_id(cell) != -1:
			break


# ---------------------------------------------------------------------------
# Hex vision (cube_line + tile validity)
# ---------------------------------------------------------------------------

## Calculate visible hex cells from a center using cube_line LoS.
##
## [code]terrain_layer[/code] is checked for valid tiles; invalid tiles block LoS.
func calculate_hex_vision(
	center_axial: Vector2i,
	radius: int,
	terrain_layer: TileMapLayer
) -> Array[Vector2i]:
	var center_cube: Vector3i = HexCoords.axial_to_cube(center_axial)
	var visible: Array[Vector2i] = [center_axial]

	# Get all hexes on the ring at the outer edge.
	var ring: Array[Vector3i] = HexCoords.cube_ring(center_cube, radius)

	for target_cube in ring:
		var line: Array[Vector3i] = HexCoords.cube_line(center_cube, target_cube)
		for cube in line:
			var axial: Vector2i = HexCoords.cube_to_axial(cube)
			# Check if tile exists.
			if terrain_layer.get_cell_source_id(axial) == -1:
				break

			if axial not in visible:
				visible.append(axial)

	return visible


# ---------------------------------------------------------------------------
# Bresenham's line algorithm
# ---------------------------------------------------------------------------

func _bresenham_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var dx: int = absi(to.x - from.x)
	var dy: int = absi(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx - dy

	var x: int = from.x
	var y: int = from.y

	while true:
		result.append(Vector2i(x, y))

		if x == to.x and y == to.y:
			break

		var e2: int = err * 2
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

	return result

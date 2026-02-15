class_name EdgeWallMap
extends RefCounted

## Stores walls on cell edges using a bitmask per cell.
##
## Walls live between two adjacent cells rather than occupying an entire cell.
## Setting a wall on one side automatically sets the reciprocal wall on the
## neighboring cell (e.g., NORTH on (2,3) sets SOUTH on (2,2)).

## Direction bitmask constants.
const NORTH: int = 1
const EAST: int = 2
const SOUTH: int = 4
const WEST: int = 8

## Maps each direction constant to its offset vector.
const DIR_OFFSETS: Dictionary = {
	NORTH: Vector2i(0, -1),
	EAST: Vector2i(1, 0),
	SOUTH: Vector2i(0, 1),
	WEST: Vector2i(-1, 0),
}

## Maps each direction to its opposite.
const OPPOSITE: Dictionary = {
	NORTH: SOUTH,
	EAST: WEST,
	SOUTH: NORTH,
	WEST: EAST,
}

## Per-cell wall bitmask: {Vector2i: int}.
var _walls: Dictionary = {}


# ---------------------------------------------------------------------------
# Wall manipulation
# ---------------------------------------------------------------------------

## Set a wall on the given edge of a cell. Automatically sets the reciprocal.
func set_wall(cell: Vector2i, dir: int) -> void:
	_walls[cell] = _walls.get(cell, 0) | dir
	var neighbor: Vector2i = cell + DIR_OFFSETS[dir]
	var opp: int = OPPOSITE[dir]
	_walls[neighbor] = _walls.get(neighbor, 0) | opp


## Clear a wall on the given edge of a cell. Automatically clears the reciprocal.
func clear_wall(cell: Vector2i, dir: int) -> void:
	if _walls.has(cell):
		_walls[cell] = _walls[cell] & ~dir
		if _walls[cell] == 0:
			_walls.erase(cell)
	var neighbor: Vector2i = cell + DIR_OFFSETS[dir]
	var opp: int = OPPOSITE[dir]
	if _walls.has(neighbor):
		_walls[neighbor] = _walls[neighbor] & ~opp
		if _walls[neighbor] == 0:
			_walls.erase(neighbor)


## Check if a wall exists on the given edge of a cell.
func has_wall(cell: Vector2i, dir: int) -> bool:
	return (_walls.get(cell, 0) & dir) != 0


# ---------------------------------------------------------------------------
# Movement / LoS queries
# ---------------------------------------------------------------------------

## Check if movement from one cell to an adjacent cell is blocked by an edge wall.
## Handles both cardinal and diagonal movement.
func is_blocked(from: Vector2i, to: Vector2i) -> bool:
	var diff: Vector2i = to - from
	# Cardinal movement: check the single edge between the two cells.
	if diff.x == 0 or diff.y == 0:
		var dir: int = _diff_to_dir(diff)
		if dir != 0:
			return has_wall(from, dir)
		return false
	# Diagonal movement: blocked if either adjacent cardinal edge has a wall.
	return is_diagonal_blocked(from, to)


## Diagonal movement is blocked if either of the two edges at the shared corner
## has a wall. For example, moving NE from (2,3) to (3,2) is blocked if
## (2,3) has NORTH or (2,3) has EAST.
func is_diagonal_blocked(from: Vector2i, to: Vector2i) -> bool:
	var diff: Vector2i = to - from
	var dir_h: int = EAST if diff.x > 0 else WEST
	var dir_v: int = NORTH if diff.y < 0 else SOUTH

	# Check edges from the source cell at the corner.
	if has_wall(from, dir_h) or has_wall(from, dir_v):
		return true

	# Also check the two intermediate cells for walls that would block the corner.
	var mid_h: Vector2i = Vector2i(to.x, from.y)  # Horizontal neighbor
	var mid_v: Vector2i = Vector2i(from.x, to.y)   # Vertical neighbor

	# If going through mid_h, check if mid_h has a wall toward to
	var dir_v_at_mid_h: int = NORTH if diff.y < 0 else SOUTH
	if has_wall(mid_h, dir_v_at_mid_h):
		return true

	# If going through mid_v, check if mid_v has a wall toward to
	var dir_h_at_mid_v: int = EAST if diff.x > 0 else WEST
	if has_wall(mid_v, dir_h_at_mid_v):
		return true

	return false


# ---------------------------------------------------------------------------
# Data access
# ---------------------------------------------------------------------------

## Return the raw wall bitmask dictionary for rendering/iteration.
func get_wall_data() -> Dictionary:
	return _walls


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serialize to a JSON-safe dictionary. Keys are "x_y" strings.
func serialize() -> Dictionary:
	var data: Dictionary = {}
	for cell: Vector2i in _walls:
		var key: String = "%d_%d" % [cell.x, cell.y]
		data[key] = _walls[cell]
	return data


## Deserialize from a previously serialized dictionary.
func deserialize(data: Dictionary) -> void:
	_walls.clear()
	for key: String in data:
		var parts: PackedStringArray = key.split("_")
		if parts.size() >= 2:
			var cell: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
			_walls[cell] = int(data[key])


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

## Convert a cardinal direction offset to a direction constant.
func _diff_to_dir(diff: Vector2i) -> int:
	if diff == Vector2i(0, -1):
		return NORTH
	if diff == Vector2i(1, 0):
		return EAST
	if diff == Vector2i(0, 1):
		return SOUTH
	if diff == Vector2i(-1, 0):
		return WEST
	return 0

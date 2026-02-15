class_name GridPathfinding
extends RefCounted

## A* pathfinding on a square grid with wall collision.
##
## Movement budget is in cells (character.speed / 5). Supports 4-directional
## and 8-directional movement. Walls are detected via a separate TileMapLayer.

## The floor layer for valid cell checks.
var _floor_layer: TileMapLayer

## The wall layer for collision checks.
var _wall_layer: TileMapLayer

## Allow diagonal movement (8 directions) or only 4.
var allow_diagonal: bool = false

## The four cardinal direction offsets.
const DIRS_4: Array[Vector2i] = [
	Vector2i( 1,  0),  # East
	Vector2i(-1,  0),  # West
	Vector2i( 0,  1),  # South
	Vector2i( 0, -1),  # North
]

## The eight directional offsets (cardinal + diagonal).
const DIRS_8: Array[Vector2i] = [
	Vector2i( 1,  0),
	Vector2i(-1,  0),
	Vector2i( 0,  1),
	Vector2i( 0, -1),
	Vector2i( 1,  1),
	Vector2i( 1, -1),
	Vector2i(-1,  1),
	Vector2i(-1, -1),
]


func _init(floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	_floor_layer = floor_layer
	_wall_layer = wall_layer


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Find the shortest path from start to goal within a movement budget.
##
## [code]max_cells[/code] limits how far the character can move (speed / 5).
## Returns an empty array if no path is found.
func find_path(start: Vector2i, goal: Vector2i, max_cells: int = 0) -> Array[Vector2i]:
	if not _is_walkable(goal):
		return [] as Array[Vector2i]

	var open_set: Array = []
	open_set.append([0.0, start])

	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {}
	came_from[start] = start
	cost_so_far[start] = 0

	var dirs: Array[Vector2i] = DIRS_8 if allow_diagonal else DIRS_4

	while not open_set.is_empty():
		open_set.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var current_entry: Array = open_set.pop_front()
		var current: Vector2i = current_entry[1]

		if current == goal:
			break

		for dir in dirs:
			var neighbor: Vector2i = current + dir

			if not _is_walkable(neighbor):
				continue

			# Diagonal movement check: prevent cutting corners.
			if dir.x != 0 and dir.y != 0:
				if not _is_walkable(Vector2i(current.x + dir.x, current.y)) or \
				   not _is_walkable(Vector2i(current.x, current.y + dir.y)):
					continue

			var step_cost: int = 2 if (dir.x != 0 and dir.y != 0) else 1
			var new_cost: int = (cost_so_far[current] as int) + step_cost

			if max_cells > 0 and new_cost > max_cells:
				continue

			if not cost_so_far.has(neighbor) or new_cost < (cost_so_far[neighbor] as int):
				cost_so_far[neighbor] = new_cost
				var priority: float = float(new_cost) + _heuristic(neighbor, goal)
				open_set.append([priority, neighbor])
				came_from[neighbor] = current

	return _reconstruct_path(came_from, start, goal)


## Get all cells reachable within a movement budget (in cells).
func get_reachable_cells(start: Vector2i, max_cells: int) -> Array[Vector2i]:
	var open_set: Array = []
	open_set.append([0, start])

	var cost_so_far: Dictionary = {}
	cost_so_far[start] = 0

	var reachable: Array[Vector2i] = [start]
	var dirs: Array[Vector2i] = DIRS_8 if allow_diagonal else DIRS_4

	while not open_set.is_empty():
		open_set.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var current_entry: Array = open_set.pop_front()
		var current: Vector2i = current_entry[1]

		for dir in dirs:
			var neighbor: Vector2i = current + dir

			if not _is_walkable(neighbor):
				continue

			if dir.x != 0 and dir.y != 0:
				if not _is_walkable(Vector2i(current.x + dir.x, current.y)) or \
				   not _is_walkable(Vector2i(current.x, current.y + dir.y)):
					continue

			var step_cost: int = 2 if (dir.x != 0 and dir.y != 0) else 1
			var new_cost: int = (cost_so_far[current] as int) + step_cost

			if new_cost > max_cells:
				continue

			if not cost_so_far.has(neighbor) or new_cost < (cost_so_far[neighbor] as int):
				cost_so_far[neighbor] = new_cost
				open_set.append([new_cost, neighbor])
				if neighbor not in reachable:
					reachable.append(neighbor)

	return reachable


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _is_walkable(cell: Vector2i) -> bool:
	# Must have a floor tile.
	if _floor_layer.get_cell_source_id(cell) == -1:
		return false
	# Must not have a wall tile.
	if _wall_layer.get_cell_source_id(cell) != -1:
		return false
	return true


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	# Chebyshev distance for 8-directional, Manhattan for 4-directional.
	if allow_diagonal:
		return float(maxi(absi(a.x - b.x), absi(a.y - b.y)))
	return float(absi(a.x - b.x) + absi(a.y - b.y))


func _reconstruct_path(came_from: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not came_from.has(goal):
		return [] as Array[Vector2i]

	var path: Array[Vector2i] = []
	var current: Vector2i = goal
	while current != start:
		path.append(current)
		current = came_from[current]
	path.append(start)
	path.reverse()
	return path

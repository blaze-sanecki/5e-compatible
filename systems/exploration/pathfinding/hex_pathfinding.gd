class_name HexPathfinding
extends RefCounted

## A* pathfinding on a hex grid with terrain-weighted costs.
##
## Uses axial coordinates (Vector2i) for TileMapLayer interop. Terrain
## costs come from HexTilemapManager. Supports a maximum cost budget.

var _tilemap_manager: HexTilemapManager


func _init(tilemap_manager: HexTilemapManager) -> void:
	_tilemap_manager = tilemap_manager


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Find the shortest path from [code]start[/code] to [code]goal[/code].
##
## Returns an array of axial cells (Vector2i). If [code]max_cost[/code] > 0,
## paths exceeding that total cost are rejected. Returns an empty array if
## no path exists.
func find_path(start: Vector2i, goal: Vector2i, max_cost: float = 0.0) -> Array[Vector2i]:
	if not _tilemap_manager.is_valid_cell(goal):
		return [] as Array[Vector2i]

	# Priority queue entries: [priority, cell]
	var open_set: Array = []
	open_set.append([0.0, start])

	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {}
	came_from[start] = start
	cost_so_far[start] = 0.0

	while not open_set.is_empty():
		# Pop lowest priority.
		open_set.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var current_entry: Array = open_set.pop_front()
		var current: Vector2i = current_entry[1]

		if current == goal:
			break

		var current_cube: Vector3i = HexCoords.axial_to_cube(current)
		var neighbor_cubes: Array[Vector3i] = HexCoords.cube_neighbors(current_cube)

		for ncube in neighbor_cubes:
			var neighbor: Vector2i = HexCoords.cube_to_axial(ncube)

			if not _tilemap_manager.is_valid_cell(neighbor):
				continue

			var move_cost: float = _tilemap_manager.get_movement_cost(neighbor)
			var new_cost: float = (cost_so_far[current] as float) + move_cost

			if max_cost > 0.0 and new_cost > max_cost:
				continue

			if not cost_so_far.has(neighbor) or new_cost < (cost_so_far[neighbor] as float):
				cost_so_far[neighbor] = new_cost
				var priority: float = new_cost + _heuristic(neighbor, goal)
				open_set.append([priority, neighbor])
				came_from[neighbor] = current

	return _reconstruct_path(came_from, start, goal)


## Return the total movement cost along a path.
func get_path_cost(path: Array[Vector2i]) -> float:
	var total: float = 0.0
	for i in range(1, path.size()):
		total += _tilemap_manager.get_movement_cost(path[i])
	return total


## Return all cells reachable within [code]max_cost[/code] movement budget.
func get_reachable_cells(start: Vector2i, max_cost: float) -> Array[Vector2i]:
	var open_set: Array = []
	open_set.append([0.0, start])

	var cost_so_far: Dictionary = {}
	cost_so_far[start] = 0.0

	var reachable: Array[Vector2i] = [start]

	while not open_set.is_empty():
		open_set.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var current_entry: Array = open_set.pop_front()
		var current: Vector2i = current_entry[1]

		var current_cube: Vector3i = HexCoords.axial_to_cube(current)
		var neighbor_cubes: Array[Vector3i] = HexCoords.cube_neighbors(current_cube)

		for ncube in neighbor_cubes:
			var neighbor: Vector2i = HexCoords.cube_to_axial(ncube)

			if not _tilemap_manager.is_valid_cell(neighbor):
				continue

			var move_cost: float = _tilemap_manager.get_movement_cost(neighbor)
			var new_cost: float = (cost_so_far[current] as float) + move_cost

			if new_cost > max_cost:
				continue

			if not cost_so_far.has(neighbor) or new_cost < (cost_so_far[neighbor] as float):
				cost_so_far[neighbor] = new_cost
				open_set.append([new_cost, neighbor])
				if neighbor not in reachable:
					reachable.append(neighbor)

	return reachable


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return float(HexCoords.axial_distance(a, b))


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

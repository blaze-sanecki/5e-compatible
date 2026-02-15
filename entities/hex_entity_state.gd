class_name HexEntityState
extends RefCounted

## Pure-logic state for a hex-overworld entity (party token).
##
## Tracks cell position, path following, and movement state.
## No visual code — the controller pairs this with a visual token.

signal cell_changed(old_cell: Vector2i, new_cell: Vector2i)
signal hex_entered(cell: Vector2i)
signal movement_started()
signal movement_completed()

## Current hex cell (axial coordinates).
var current_cell: Vector2i = Vector2i.ZERO

## Whether a multi-cell path is currently being followed.
var is_moving: bool = false

## The path being followed in cell coordinates.
var path_cells: Array[Vector2i] = []

## Index of the next cell in the path.
var path_index: int = 0


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func _init(start_cell: Vector2i = Vector2i.ZERO) -> void:
	current_cell = start_cell


# ---------------------------------------------------------------------------
# Path movement
# ---------------------------------------------------------------------------

## Begin following a path of cells. The first cell should be the current cell.
func start_path(cells: Array[Vector2i]) -> void:
	if cells.size() < 2:
		return
	path_cells = cells
	path_index = 1  # Skip the starting cell (index 0).
	is_moving = true
	movement_started.emit()


## Get the next target cell in the path, or Vector2i(-9999, -9999) if done.
func get_next_target_cell() -> Vector2i:
	if path_index >= path_cells.size():
		return Vector2i(-9999, -9999)
	return path_cells[path_index]


## Commit arrival at the current path cell. Returns the cell reached.
func commit_cell_reached() -> Vector2i:
	var old_cell: Vector2i = current_cell
	var reached: Vector2i = path_cells[path_index]
	current_cell = reached
	path_index += 1
	cell_changed.emit(old_cell, reached)
	hex_entered.emit(reached)
	return reached


## Whether the path has been fully traversed.
func is_path_complete() -> bool:
	return path_index >= path_cells.size()


## Call when the entire path is finished.
func complete_movement() -> void:
	is_moving = false
	path_cells.clear()
	path_index = 0
	movement_completed.emit()


## Stop movement mid-path (e.g. encounter triggered).
func stop_movement() -> void:
	is_moving = false
	path_cells.clear()
	path_index = 0


## Teleport to a cell with no path or animation.
func teleport(cell: Vector2i) -> void:
	var old_cell: Vector2i = current_cell
	current_cell = cell
	cell_changed.emit(old_cell, cell)

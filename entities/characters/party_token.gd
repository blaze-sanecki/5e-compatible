class_name PartyToken
extends Node2D

## Visual representation of the player's party on the hex overworld.
##
## Handles click-to-move input, smooth Tween-based movement along a path,
## and signals when movement starts/completes.

signal movement_started()
signal movement_completed()
signal hex_entered(cell: Vector2i)

## Movement speed in pixels per second for the tween.
@export var move_speed: float = 200.0

## The current hex cell (axial coordinates).
var current_cell: Vector2i = Vector2i.ZERO

## Whether the token is currently moving.
var is_moving: bool = false

## The path being followed (array of world positions).
var _path_positions: Array[Vector2] = []

## Current tween for movement animation.
var _move_tween: Tween

## The path in cell coordinates (used for hex_entered signals).
var _path_cells: Array[Vector2i] = []

## Index of the next cell in the path.
var _path_index: int = 0

## Reference to the tilemap manager for coordinate conversion.
var _tilemap_manager: HexTilemapManager


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func setup(tilemap_manager: HexTilemapManager, start_cell: Vector2i) -> void:
	_tilemap_manager = tilemap_manager
	current_cell = start_cell
	position = tilemap_manager.cell_to_world(start_cell)


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Move the token along a path of hex cells.
func move_along_path(path_cells: Array[Vector2i]) -> void:
	if path_cells.size() < 2:
		return
	if is_moving:
		return

	_path_cells = path_cells
	_path_index = 1  # Skip the starting cell (index 0).

	is_moving = true
	movement_started.emit()
	_move_to_next_cell()


## Teleport the token to a cell without animation.
func teleport_to(cell: Vector2i) -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	is_moving = false
	current_cell = cell
	position = _tilemap_manager.cell_to_world(cell)


# ---------------------------------------------------------------------------
# Internal movement
# ---------------------------------------------------------------------------

func _move_to_next_cell() -> void:
	if _path_index >= _path_cells.size():
		_on_movement_complete()
		return

	var target_cell: Vector2i = _path_cells[_path_index]
	var target_pos: Vector2 = _tilemap_manager.cell_to_world(target_cell)
	var distance: float = position.distance_to(target_pos)
	var duration: float = distance / move_speed

	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target_pos, duration)
	_move_tween.finished.connect(_on_cell_reached)


func _on_cell_reached() -> void:
	var reached_cell: Vector2i = _path_cells[_path_index]
	current_cell = reached_cell
	hex_entered.emit(reached_cell)

	_path_index += 1
	_move_to_next_cell()


func _on_movement_complete() -> void:
	is_moving = false
	_path_cells.clear()
	_path_index = 0
	movement_completed.emit()

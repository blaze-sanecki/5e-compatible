class_name CharacterToken
extends Node2D

## Visual representation of a single character on a square grid dungeon.
##
## Tracks movement remaining per turn, selection state, and emits signals
## when the character moves or is selected.

signal selected()
signal deselected()
signal moved_to(cell: Vector2i)
signal movement_exhausted()

## The CharacterData resource this token represents.
@export var character_data: Resource

## Current grid cell position.
var current_cell: Vector2i = Vector2i.ZERO

## Movement remaining in feet this turn.
var movement_remaining: int = 30

## Whether this token is currently selected (player-controlled).
var is_selected: bool = false

## Whether the token is currently animating a move.
var is_moving: bool = false

## Movement speed in pixels per second for tweening.
@export var move_speed: float = 300.0

## Reference to the floor layer for coordinate conversion.
var _floor_layer: TileMapLayer

## Current movement tween.
var _move_tween: Tween


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Initialize the token with a character and starting cell.
func setup(data: Resource, floor_layer: TileMapLayer, start_cell: Vector2i) -> void:
	character_data = data
	_floor_layer = floor_layer
	current_cell = start_cell
	position = floor_layer.map_to_local(start_cell)
	_reset_movement()


## Reset movement remaining based on character speed.
func _reset_movement() -> void:
	if character_data and character_data.get("speed"):
		movement_remaining = character_data.speed
	else:
		movement_remaining = 30


# ---------------------------------------------------------------------------
# Selection
# ---------------------------------------------------------------------------

func select() -> void:
	is_selected = true
	modulate = Color(1.2, 1.2, 1.0, 1.0)
	selected.emit()


func deselect() -> void:
	is_selected = false
	modulate = Color.WHITE
	deselected.emit()


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Move one cell in the given direction. Returns true if move succeeded.
func move_to_cell(target_cell: Vector2i) -> bool:
	if is_moving:
		return false
	if _floor_layer == null:
		return false

	# Only enforce movement budget during combat.
	if GameManager.is_in_combat():
		var diff: Vector2i = target_cell - current_cell
		var is_diagonal: bool = diff.x != 0 and diff.y != 0
		var cost: int = 10 if is_diagonal else 5

		if movement_remaining < cost:
			return false

		movement_remaining -= cost

	is_moving = true

	var target_pos: Vector2 = _floor_layer.map_to_local(target_cell)
	var distance: float = position.distance_to(target_pos)
	var duration: float = distance / move_speed

	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target_pos, duration)
	_move_tween.finished.connect(func() -> void:
		current_cell = target_cell
		is_moving = false
		moved_to.emit(target_cell)
		if movement_remaining <= 0:
			movement_exhausted.emit()
	)

	return true


## Move along a path of cells. Stops when movement is exhausted.
func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return
	_move_path_step(path, 1)


func _move_path_step(path: Array[Vector2i], index: int) -> void:
	if index >= path.size():
		return
	if not move_to_cell(path[index]):
		return
	# Wait for the current move to finish, then continue.
	await moved_to
	if movement_remaining > 0 and index + 1 < path.size():
		_move_path_step(path, index + 1)


## Teleport without animation or cost.
func teleport_to(cell: Vector2i) -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	current_cell = cell
	position = _floor_layer.map_to_local(cell)
	is_moving = false


## Reset movement for a new turn.
func new_turn() -> void:
	_reset_movement()


## Get movement cells remaining (speed / 5).
func get_cells_remaining() -> int:
	@warning_ignore("integer_division")
	return movement_remaining / 5

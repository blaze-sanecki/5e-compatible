class_name GridEntityState
extends RefCounted

## Pure-logic state for a square-grid entity (character or monster).
##
## Tracks cell position, movement budget, and selection state.
## No visual code — controllers pair this with a visual token.

signal cell_changed(old_cell: Vector2i, new_cell: Vector2i)
signal movement_exhausted()
signal state_changed(property: StringName, value: Variant)

## Current grid cell position.
var current_cell: Vector2i = Vector2i.ZERO

## Movement remaining in feet this turn.
var movement_remaining: int = 30

## Whether this entity is currently moving (animation in progress).
var is_moving: bool = false

## Whether this entity is currently selected.
var is_selected: bool = false

## Base movement speed in feet per turn.
var speed: int = 30


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func _init(start_cell: Vector2i = Vector2i.ZERO, base_speed: int = 30) -> void:
	current_cell = start_cell
	speed = base_speed
	movement_remaining = base_speed


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Try a move from the current cell. Returns the movement cost in feet,
## or -1 if the move would exceed the budget.
## If enforce_budget is false, always returns the cost without checking.
func try_move(target: Vector2i, enforce_budget: bool = true) -> int:
	var diff: Vector2i = target - current_cell
	var is_diagonal: bool = diff.x != 0 and diff.y != 0
	var cost: int = 10 if is_diagonal else 5

	if enforce_budget and movement_remaining < cost:
		return -1

	return cost


## Finalize a move — deduct cost and update cell.
func commit_move(new_cell: Vector2i, cost: int = -1) -> void:
	var old_cell: Vector2i = current_cell

	if cost < 0:
		# Auto-calculate cost.
		var diff: Vector2i = new_cell - current_cell
		var is_diagonal: bool = diff.x != 0 and diff.y != 0
		cost = 10 if is_diagonal else 5

	movement_remaining -= cost
	current_cell = new_cell
	cell_changed.emit(old_cell, new_cell)

	if movement_remaining <= 0:
		movement_exhausted.emit()


## Teleport to a cell with no cost or animation.
func teleport(cell: Vector2i) -> void:
	var old_cell: Vector2i = current_cell
	current_cell = cell
	cell_changed.emit(old_cell, cell)


## Select this entity.
func select() -> void:
	is_selected = true
	state_changed.emit(&"is_selected", true)


## Deselect this entity.
func deselect() -> void:
	is_selected = false
	state_changed.emit(&"is_selected", false)


## Reset movement for a new turn.
func new_turn() -> void:
	movement_remaining = speed


## Get remaining movement in cells (speed / 5).
func get_cells_remaining() -> int:
	@warning_ignore("integer_division")
	return movement_remaining / 5

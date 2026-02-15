class_name FogOfWarSystem
extends RefCounted

## Manages a fog-of-war TileMapLayer with three visibility states.
##
## - UNEXPLORED (0): Never seen, fully dark.
## - EXPLORED (1): Previously seen, dimmed.
## - VISIBLE (2): Currently in line of sight, fully revealed.
##
## The fog layer uses tile atlas coordinates to represent each state:
## (0,0) = dark/unexplored, (1,0) = dim/explored, no tile = visible/clear.

enum FogState { UNEXPLORED, EXPLORED, VISIBLE }

## Stores the current fog state for every cell: cell -> FogState.
var _fog_data: Dictionary = {}

## Reference to the fog TileMapLayer.
var _fog_layer: TileMapLayer

## Source ID for fog tiles.
var _fog_source_id: int = 0

## Atlas coords for unexplored (dark).
var unexplored_atlas: Vector2i = Vector2i(0, 0)

## Atlas coords for explored (dim).
var explored_atlas: Vector2i = Vector2i(1, 0)


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

## Initialize fog for a hex map. All cells start as UNEXPLORED.
func initialize_hex(fog_layer: TileMapLayer, all_cells: Array[Vector2i]) -> void:
	_fog_layer = fog_layer
	_init_cells(all_cells)


## Initialize fog for a grid map. All cells start as UNEXPLORED.
func initialize_grid(fog_layer: TileMapLayer, all_cells: Array[Vector2i]) -> void:
	_fog_layer = fog_layer
	_init_cells(all_cells)


func _init_cells(all_cells: Array[Vector2i]) -> void:
	_fog_data.clear()
	for cell in all_cells:
		_fog_data[cell] = FogState.UNEXPLORED
	_apply_fog()


# ---------------------------------------------------------------------------
# Visibility updates
# ---------------------------------------------------------------------------

## Update visibility: cells in [code]visible_cells[/code] become VISIBLE,
## previously VISIBLE cells become EXPLORED, UNEXPLORED cells stay dark.
func update_visibility(visible_cells: Array[Vector2i]) -> void:
	# Demote all currently VISIBLE cells to EXPLORED.
	for cell in _fog_data:
		if _fog_data[cell] == FogState.VISIBLE:
			_fog_data[cell] = FogState.EXPLORED

	# Mark the new visible cells.
	for cell in visible_cells:
		if _fog_data.has(cell):
			_fog_data[cell] = FogState.VISIBLE

	_apply_fog()


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _apply_fog() -> void:
	if _fog_layer == null:
		return

	for cell in _fog_data:
		var state: int = _fog_data[cell] as int
		match state:
			FogState.UNEXPLORED:
				_fog_layer.set_cell(cell, _fog_source_id, unexplored_atlas)
			FogState.EXPLORED:
				_fog_layer.set_cell(cell, _fog_source_id, explored_atlas)
			FogState.VISIBLE:
				# Clear the fog tile to reveal the terrain underneath.
				_fog_layer.erase_cell(cell)


# ---------------------------------------------------------------------------
# Save / Load state
# ---------------------------------------------------------------------------

## Export fog state as a Dictionary for saving.
func save_state() -> Dictionary:
	var state: Dictionary = {}
	for cell in _fog_data:
		var key: String = "%d_%d" % [cell.x, cell.y]
		state[key] = _fog_data[cell]
	return state


## Import fog state from a saved Dictionary.
func load_state(state: Dictionary) -> void:
	for key in state:
		var parts: PackedStringArray = key.split("_")
		if parts.size() == 2:
			var cell: Vector2i = Vector2i(parts[0].to_int(), parts[1].to_int())
			if _fog_data.has(cell):
				_fog_data[cell] = state[key] as int
	_apply_fog()


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

## Get the fog state of a specific cell.
func get_cell_state(cell: Vector2i) -> FogState:
	if _fog_data.has(cell):
		return _fog_data[cell] as FogState
	return FogState.UNEXPLORED


## Check if a cell is currently visible.
func is_visible(cell: Vector2i) -> bool:
	return get_cell_state(cell) == FogState.VISIBLE


## Check if a cell has been explored (visible or previously seen).
func is_explored(cell: Vector2i) -> bool:
	var state: FogState = get_cell_state(cell)
	return state == FogState.VISIBLE or state == FogState.EXPLORED

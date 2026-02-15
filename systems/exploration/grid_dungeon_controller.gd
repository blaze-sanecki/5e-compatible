class_name GridDungeonController
extends Node2D

## Root controller for square-grid dungeon maps.
##
## Handles WASD movement, click-to-move, Tab to cycle party members,
## fog of war updates, and interaction with dungeon objects.

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@export var floor_layer_path: NodePath
@export var wall_layer_path: NodePath
@export var fog_layer_path: NodePath
@export var camera_path: NodePath

var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var fog_layer: TileMapLayer
var camera: Camera2D

## Sub-systems.
var pathfinder: GridPathfinding
var fog_system: FogOfWarSystem
var vision_calc: VisionCalculator

## Character tokens indexed by party slot.
var character_tokens: Array[CharacterToken] = []

## Currently selected token index.
var selected_token_index: int = 0

## Vision range in grid cells.
@export var vision_range: int = 6

## Map data resource (optional, assigned in scene or code).
@export var map_data: GridMapData

## Generate a placeholder test dungeon if the floor layer is empty.
@export var generate_test_map: bool = true


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	floor_layer = get_node(floor_layer_path) as TileMapLayer
	wall_layer = get_node(wall_layer_path) as TileMapLayer
	fog_layer = get_node(fog_layer_path) as TileMapLayer
	camera = get_node(camera_path) as Camera2D

	# Generate a test dungeon if layers are empty.
	if generate_test_map and floor_layer.get_used_cells().is_empty():
		var interactables: Node = get_node_or_null("Interactables")
		var token: CharacterToken = TestMapGenerator.generate_grid_dungeon(
			floor_layer, wall_layer, fog_layer, interactables, self
		)
		if token:
			character_tokens.append(token)
			token.select()
			selected_token_index = 0

	pathfinder = GridPathfinding.new(floor_layer, wall_layer)
	fog_system = FogOfWarSystem.new()
	vision_calc = VisionCalculator.new()

	# Initialize fog of war for all floor cells.
	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	fog_system.initialize_grid(fog_layer, used_cells)

	if not character_tokens.is_empty():
		_update_fog()
		_update_camera()

	GameManager.change_state(GameManager.GameState.EXPLORING)


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_exploring():
		return

	var active_token: CharacterToken = _get_active_token()
	if active_token == null:
		return
	if active_token.is_moving:
		return

	# WASD movement + E interact + Tab cycle.
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey

		# E or Space: interact with adjacent interactable.
		if key.keycode == KEY_E or key.keycode == KEY_SPACE:
			_try_interact(active_token)
			get_viewport().set_input_as_handled()
			return

		var direction: Vector2i = _key_to_direction(key.keycode)
		if direction != Vector2i.ZERO:
			_try_move(active_token, direction)
			get_viewport().set_input_as_handled()
			return

		# Tab: cycle selected character.
		if key.keycode == KEY_TAB:
			_cycle_selected_token()
			get_viewport().set_input_as_handled()
			return

	# Click-to-move.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb, active_token)


# ---------------------------------------------------------------------------
# Input helpers
# ---------------------------------------------------------------------------

func _key_to_direction(keycode: Key) -> Vector2i:
	match keycode:
		KEY_W, KEY_UP:
			return Vector2i(0, -1)
		KEY_S, KEY_DOWN:
			return Vector2i(0, 1)
		KEY_A, KEY_LEFT:
			return Vector2i(-1, 0)
		KEY_D, KEY_RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO


func _try_move(token: CharacterToken, direction: Vector2i) -> void:
	var target: Vector2i = token.current_cell + direction

	if not pathfinder._is_walkable(target):
		return

	# Check for interactables that block movement (e.g. closed doors).
	var interactable: Node = _get_interactable_at(target)
	if interactable and interactable.has_method("blocks_movement"):
		if interactable.blocks_movement():
			return

	if token.move_to_cell(target):
		await token.moved_to
		_update_fog()
		_update_camera()


func _handle_click(event: InputEventMouseButton, token: CharacterToken) -> void:
	var world_pos: Vector2 = get_canvas_transform().affine_inverse() * event.position
	var target_cell: Vector2i = floor_layer.local_to_map(world_pos)

	if target_cell == token.current_cell:
		return

	var max_cells: int = token.get_cells_remaining() if GameManager.is_in_combat() else 0
	var path: Array[Vector2i] = pathfinder.find_path(
		token.current_cell, target_cell, max_cells
	)
	if path.is_empty():
		return

	token.move_along_path(path)
	# Update fog after each step via the token's moved_to signal.
	if not token.moved_to.is_connected(_on_token_moved):
		token.moved_to.connect(_on_token_moved)


func _on_token_moved(_cell: Vector2i) -> void:
	_update_fog()
	_update_camera()


# ---------------------------------------------------------------------------
# Token management
# ---------------------------------------------------------------------------

## Spawn character tokens from the party roster at the given spawn point.
func spawn_party(spawn_id: StringName) -> void:
	var spawn_cell: Vector2i = Vector2i.ZERO
	if map_data and map_data.spawn_points.has(spawn_id):
		spawn_cell = map_data.spawn_points[spawn_id]

	for i in PartyManager.party.size():
		var character: Resource = PartyManager.party[i]
		var token: CharacterToken = CharacterToken.new()
		token.name = "CharToken_%d" % i
		add_child(token)

		# Offset each character by one cell so they don't stack.
		var cell: Vector2i = spawn_cell + Vector2i(i, 0)
		token.setup(character, floor_layer, cell)
		character_tokens.append(token)

	if not character_tokens.is_empty():
		character_tokens[0].select()
		selected_token_index = 0
		_update_fog()
		_update_camera()


func _get_active_token() -> CharacterToken:
	if character_tokens.is_empty():
		return null
	if selected_token_index >= character_tokens.size():
		return null
	return character_tokens[selected_token_index]


func _cycle_selected_token() -> void:
	if character_tokens.size() <= 1:
		return

	var old_token: CharacterToken = _get_active_token()
	if old_token:
		old_token.deselect()

	selected_token_index = (selected_token_index + 1) % character_tokens.size()
	var new_token: CharacterToken = _get_active_token()
	if new_token:
		new_token.select()
		PartyManager.set_active_character(selected_token_index)
		_update_camera()


# ---------------------------------------------------------------------------
# Fog of war
# ---------------------------------------------------------------------------

func _update_fog() -> void:
	var all_visible: Array[Vector2i] = []

	for token in character_tokens:
		var visible_cells: Array[Vector2i] = vision_calc.calculate_grid_vision(
			token.current_cell, vision_range, floor_layer, wall_layer
		)
		for cell in visible_cells:
			if cell not in all_visible:
				all_visible.append(cell)

	fog_system.update_visibility(all_visible)


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	var active_token: CharacterToken = _get_active_token()
	if active_token == null or camera == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(camera, "position", active_token.position, 0.2).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

## Try to interact with the nearest adjacent interactable.
func _try_interact(token: CharacterToken) -> void:
	var best: Node = null
	var best_dist: float = INF

	for dir in GridPathfinding.DIRS_4:
		var neighbor: Vector2i = token.current_cell + dir
		var found: Node = _get_interactable_at(neighbor)
		if found:
			best = found
			break  # Take the first one found.

	# Also check the cell the character is standing on.
	if best == null:
		best = _get_interactable_at(token.current_cell)

	if best and best.has_method("interact"):
		best.interact()
		EventBus.interaction_triggered.emit(best)


## Find an interactable at the given cell by comparing positions directly.
func _get_interactable_at(cell: Vector2i) -> Node:
	var interactables_parent: Node = get_node_or_null("Interactables")
	if interactables_parent == null:
		return null

	var cell_world: Vector2 = floor_layer.map_to_local(cell)
	var threshold: float = float(floor_layer.tile_set.tile_size.x) * 0.6 if floor_layer.tile_set else 20.0

	for child in interactables_parent.get_children():
		if not child.has_method("interact"):
			continue
		if child is Node2D:
			var dist: float = (child as Node2D).position.distance_to(cell_world)
			if dist < threshold:
				return child

	return null

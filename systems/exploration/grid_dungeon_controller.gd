class_name GridDungeonController
extends Node2D

## Root controller for square-grid dungeon maps.
##
## Orchestrates input, fog of war, camera, and interactions.
## Delegates token management to GridTokenManager and combat
## encounter lifecycle to GridEncounterInitializer.

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
var _camera_tween: Tween

## Sub-systems.
var pathfinder: GridPathfinding
var fog_system: FogOfWarSystem
var vision_calc: VisionCalculator

## Vision range in grid cells.
@export var vision_range: int = 6

## Map data resource (optional, assigned in scene or code).
@export var map_data: GridMapData

## Generate a placeholder test dungeon if the floor layer is empty.
@export var generate_test_map: bool = true

## Delegated helpers.
var token_manager: GridTokenManager
var encounter_init: GridEncounterInitializer

## Combat sub-systems (set by GridEncounterInitializer).
var combat_manager: CombatManager
var combat_grid_controller: CombatGridController


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	floor_layer = get_node(floor_layer_path) as TileMapLayer
	wall_layer = get_node(wall_layer_path) as TileMapLayer
	fog_layer = get_node(fog_layer_path) as TileMapLayer
	camera = get_node(camera_path) as Camera2D

	token_manager = GridTokenManager.new(floor_layer, self)
	encounter_init = GridEncounterInitializer.new(self)

	# Generate a test dungeon if layers are empty.
	if generate_test_map and floor_layer.get_used_cells().is_empty():
		var interactables: Node = get_node_or_null("Interactables")
		if PartyManager.party.is_empty():
			var token: CharacterToken = TestMapGenerator.generate_grid_dungeon(
				floor_layer, wall_layer, fog_layer, interactables, self
			)
			if token:
				var start_cell: Vector2i = Vector2i(3, 3)
				var base_speed: int = token.character_data.speed if token.character_data and token.character_data.get("speed") else 30
				var state := GridEntityState.new(start_cell, base_speed)
				token_manager.character_states.append(state)
				token_manager.character_tokens.append(token)
				state.select()
				token.set_selected_visual(true)
				token_manager.selected_token_index = 0
		else:
			TestMapGenerator.generate_grid_dungeon_map_only(
				floor_layer, wall_layer, fog_layer, interactables
			)

		var npcs_node: Node = get_node_or_null("NPCs")
		if npcs_node:
			TestMapGenerator.setup_dialogue_npcs(npcs_node, floor_layer)

	pathfinder = GridPathfinding.new(floor_layer, wall_layer)
	fog_system = FogOfWarSystem.new()
	vision_calc = VisionCalculator.new()

	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	fog_system.initialize_grid(fog_layer, used_cells)

	if not token_manager.character_tokens.is_empty():
		_update_fog()
		_update_camera()

	encounter_init.setup_triggers()
	GameManager.change_state(GameManager.GameState.EXPLORING)


func _unhandled_input(event: InputEvent) -> void:
	# Delegate to combat controller during combat.
	if GameManager.is_in_combat() and combat_grid_controller != null:
		if combat_grid_controller.handle_input(event):
			get_viewport().set_input_as_handled()
		return

	if GameManager.current_state == GameManager.GameState.DIALOGUE:
		return

	if not GameManager.is_exploring():
		return

	var active_token: CharacterToken = token_manager.get_active_token()
	var active_state: GridEntityState = token_manager.get_active_state()
	if active_token == null or active_state == null:
		return
	if active_state.is_moving:
		return

	# WASD movement + E interact + Tab cycle.
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey

		if key.keycode == KEY_E or key.keycode == KEY_SPACE:
			_try_interact(active_state)
			get_viewport().set_input_as_handled()
			return

		var direction: Vector2i = _key_to_direction(key.keycode)
		if direction != Vector2i.ZERO:
			_try_move(active_state, active_token, direction)
			get_viewport().set_input_as_handled()
			return

		if key.keycode == KEY_TAB:
			token_manager.cycle_selected()
			_update_camera()
			get_viewport().set_input_as_handled()
			return

	# Click-to-move.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb, active_state, active_token)


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


func _try_move(state: GridEntityState, token: CharacterToken, direction: Vector2i) -> void:
	var target: Vector2i = state.current_cell + direction

	if not pathfinder._is_walkable(target):
		return

	var interactable: Node = _get_interactable_at(target)
	if interactable and interactable.has_method("blocks_movement"):
		if interactable.blocks_movement():
			return

	if GameManager.is_in_combat():
		var cost: int = state.try_move(target, true)
		if cost < 0:
			return

	state.is_moving = true
	var target_pos: Vector2 = floor_layer.map_to_local(target)
	token.animate_move_to(target_pos)
	await token.animation_finished
	state.commit_move(target)
	state.is_moving = false
	_update_fog()
	_update_camera()
	encounter_init.check_triggers(target)


func _handle_click(event: InputEventMouseButton, state: GridEntityState, token: CharacterToken) -> void:
	var world_pos: Vector2 = get_canvas_transform().affine_inverse() * event.position
	var target_cell: Vector2i = floor_layer.local_to_map(world_pos)

	if target_cell == state.current_cell:
		return

	var max_cells: int = state.get_cells_remaining() if GameManager.is_in_combat() else 0
	var path: Array[Vector2i] = pathfinder.find_path(
		state.current_cell, target_cell, max_cells
	)
	if path.is_empty():
		return

	state.is_moving = true
	for i in range(1, path.size()):
		var cell: Vector2i = path[i]
		if GameManager.is_in_combat():
			var cost: int = state.try_move(cell, true)
			if cost < 0:
				break

		var cell_pos: Vector2 = floor_layer.map_to_local(cell)
		token.animate_move_to(cell_pos)
		await token.animation_finished
		state.commit_move(cell)
		_update_fog()
		_update_camera()
		encounter_init.check_triggers(cell)
	state.is_moving = false


# ---------------------------------------------------------------------------
# Fog of war
# ---------------------------------------------------------------------------

func _update_fog() -> void:
	var all_visible: Array[Vector2i] = []

	for state in token_manager.character_states:
		var visible_cells: Array[Vector2i] = vision_calc.calculate_grid_vision(
			state.current_cell, vision_range, floor_layer, wall_layer
		)
		for cell in visible_cells:
			if cell not in all_visible:
				all_visible.append(cell)

	fog_system.update_visibility(all_visible)


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

## Kill any camera tween and snap to the active token instantly.
func snap_camera() -> void:
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	var active_token: CharacterToken = token_manager.get_active_token()
	if active_token and camera:
		camera.position = active_token.position
		camera.reset_smoothing()


func _update_camera() -> void:
	var active_token: CharacterToken = token_manager.get_active_token()
	if active_token == null or camera == null:
		return
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "position", active_token.position, 0.2).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

func _try_interact(state: GridEntityState) -> void:
	var best: Node = null

	for dir in GridPathfinding.DIRS_4:
		var neighbor: Vector2i = state.current_cell + dir
		var found: Node = _get_interactable_at(neighbor)
		if found:
			best = found
			break

	if best == null:
		best = _get_interactable_at(state.current_cell)

	if best and best.has_method("interact"):
		best.interact()
		EventBus.interaction_triggered.emit(best)


func _get_interactable_at(cell: Vector2i) -> Node:
	var cell_world: Vector2 = floor_layer.map_to_local(cell)
	var threshold: float = float(floor_layer.tile_set.tile_size.x) * 0.6 if floor_layer.tile_set else 20.0

	for parent_name in ["Interactables", "NPCs"]:
		var parent: Node = get_node_or_null(parent_name)
		if parent == null:
			continue
		for child in parent.get_children():
			if not child.has_method("interact"):
				continue
			if child is Node2D:
				var dist: float = (child as Node2D).position.distance_to(cell_world)
				if dist < threshold:
					return child

	return null


# ---------------------------------------------------------------------------
# Public API (called externally via has_method)
# ---------------------------------------------------------------------------

## Spawn party tokens at a named spawn point.
func spawn_party(spawn_id: StringName) -> void:
	var spawn_cell: Vector2i = Vector2i(3, 3)
	if map_data and map_data.spawn_points.has(spawn_id):
		spawn_cell = map_data.spawn_points[spawn_id]
	token_manager.spawn_party(spawn_cell)
	_update_fog()
	_update_camera()


## Start a combat encounter (called by CombatEncounterTrigger / DialogueManager).
func start_encounter(encounter: CombatEncounterData) -> void:
	encounter_init.start_encounter(encounter)


## Get references needed by the combat system.
func get_combat_references() -> Dictionary:
	return {
		"floor_layer": floor_layer,
		"wall_layer": wall_layer,
		"pathfinder": pathfinder,
		"character_tokens": token_manager.character_tokens,
		"controller": self,
	}


# ---------------------------------------------------------------------------
# Save / Load state
# ---------------------------------------------------------------------------

func get_save_state() -> Dictionary:
	var data: Dictionary = {}

	var positions: Array = []
	for state in token_manager.character_states:
		positions.append([state.current_cell.x, state.current_cell.y])
	data["character_positions"] = positions

	if fog_system:
		data["fog_of_war"] = fog_system.save_state()

	var interactable_states: Dictionary = {}
	var interactables_node: Node = get_node_or_null("Interactables")
	if interactables_node:
		for child in interactables_node.get_children():
			var state: Dictionary = {}
			if child is DoorInteractable:
				state["is_open"] = child.is_open
				if child.interactable_data:
					state["is_locked"] = child.interactable_data.is_locked
			elif child is ChestInteractable:
				state["is_looted"] = child.is_looted
			elif child is LeverInteractable:
				state["is_activated"] = child.is_activated
			if not state.is_empty():
				interactable_states[child.name] = state
	data["interactables"] = interactable_states

	var trigger_states: Dictionary = {}
	var triggers_node: Node = get_node_or_null("EncounterTriggers")
	if triggers_node:
		for child in triggers_node.get_children():
			if child is CombatEncounterTrigger:
				trigger_states[child.name] = child.triggered
	data["encounter_triggers"] = trigger_states

	return data


func restore_save_state(data: Dictionary) -> void:
	if data.is_empty():
		return

	var positions: Array = data.get("character_positions", [])
	for i in mini(positions.size(), token_manager.character_states.size()):
		var pos: Array = positions[i]
		if pos.size() >= 2:
			var cell: Vector2i = Vector2i(int(pos[0]), int(pos[1]))
			token_manager.character_states[i].teleport(cell)
			if i < token_manager.character_tokens.size():
				token_manager.character_tokens[i].teleport_visual(floor_layer.map_to_local(cell))

	var fog_data: Dictionary = data.get("fog_of_war", {})
	if not fog_data.is_empty() and fog_system:
		fog_system.load_state(fog_data)

	var interactable_states: Dictionary = data.get("interactables", {})
	var interactables_node: Node = get_node_or_null("Interactables")
	if interactables_node:
		for child in interactables_node.get_children():
			if not interactable_states.has(child.name):
				continue
			var state: Dictionary = interactable_states[child.name]
			if child is DoorInteractable:
				if state.get("is_open", false):
					child.force_open()
				if child.interactable_data and state.has("is_locked"):
					child.interactable_data.is_locked = state["is_locked"]
			elif child is ChestInteractable:
				if state.get("is_looted", false):
					child.is_looted = true
					child._update_visual()
					if child.interactable_data:
						child.interactable_data.is_used = true
			elif child is LeverInteractable:
				if state.get("is_activated", false) != child.is_activated:
					child._perform_interaction()

	var trigger_states: Dictionary = data.get("encounter_triggers", {})
	var triggers_node: Node = get_node_or_null("EncounterTriggers")
	if triggers_node:
		for child in triggers_node.get_children():
			if child is CombatEncounterTrigger and trigger_states.has(child.name):
				child.triggered = trigger_states[child.name]

	_update_fog()

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

## Combat sub-systems (created on demand).
var combat_manager: CombatManager
var combat_grid_controller: CombatGridController
var monster_tokens: Array[MonsterToken] = []


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
		if PartyManager.party.is_empty():
			# No party yet (standalone testing) — create test token + placeholder character.
			var token: CharacterToken = TestMapGenerator.generate_grid_dungeon(
				floor_layer, wall_layer, fog_layer, interactables, self
			)
			if token:
				character_tokens.append(token)
				token.select()
				selected_token_index = 0
		else:
			# Party exists (coming from character creation) — generate map only, no test token.
			TestMapGenerator.generate_grid_dungeon_map_only(
				floor_layer, wall_layer, fog_layer, interactables
			)

		# Set up NPC positions if the NPCs node exists.
		var npcs_node: Node = get_node_or_null("NPCs")
		if npcs_node:
			TestMapGenerator.setup_dialogue_npcs(npcs_node, floor_layer)

	pathfinder = GridPathfinding.new(floor_layer, wall_layer)
	fog_system = FogOfWarSystem.new()
	vision_calc = VisionCalculator.new()

	# Initialize fog of war for all floor cells.
	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	fog_system.initialize_grid(fog_layer, used_cells)

	if not character_tokens.is_empty():
		_update_fog()
		_update_camera()

	# Set up encounter trigger positions (place them at their cell locations).
	_setup_encounter_triggers()

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
		_check_encounter_triggers(target)


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


func _on_token_moved(cell: Vector2i) -> void:
	_update_fog()
	_update_camera()
	_check_encounter_triggers(cell)


# ---------------------------------------------------------------------------
# Token management
# ---------------------------------------------------------------------------

## Spawn character tokens from the party roster at the given spawn point.
func spawn_party(spawn_id: StringName) -> void:
	var spawn_cell: Vector2i = Vector2i(3, 3)  # Default to room 1 center.
	if map_data and map_data.spawn_points.has(spawn_id):
		spawn_cell = map_data.spawn_points[spawn_id]

	for i in PartyManager.party.size():
		var character: Resource = PartyManager.party[i]
		var token: CharacterToken = CharacterToken.new()
		token.name = "CharToken_%d" % i
		add_child(token)

		# Give the token a visible sprite.
		var color: Color = [
			Color(0.2, 0.6, 1.0), Color(0.2, 0.9, 0.3),
			Color(0.9, 0.4, 0.2), Color(0.8, 0.2, 0.8),
		][i % 4]
		var sprite := Sprite2D.new()
		sprite.texture = TestMapGenerator.create_circle_texture(20, color)
		token.add_child(sprite)

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
## Scans both the Interactables and NPCs nodes.
func _get_interactable_at(cell: Vector2i) -> Node:
	var cell_world: Vector2 = floor_layer.map_to_local(cell)
	var threshold: float = float(floor_layer.tile_set.tile_size.x) * 0.6 if floor_layer.tile_set else 20.0

	# Scan both Interactables and NPCs parents.
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
# Encounter triggers
# ---------------------------------------------------------------------------

func _setup_encounter_triggers() -> void:
	var triggers_parent: Node = get_node_or_null("EncounterTriggers")
	if triggers_parent == null:
		return
	for child in triggers_parent.get_children():
		if child is CombatEncounterTrigger:
			var trigger: CombatEncounterTrigger = child as CombatEncounterTrigger
			# If trigger_cell is still at (0,0) and the trigger has no custom position,
			# place it at the first monster spawn cell of its encounter.
			if trigger.trigger_cell == Vector2i.ZERO:
				var encounter: CombatEncounterData = DataRegistry.get_encounter(trigger.encounter_id)
				if encounter and not encounter.monster_spawns.is_empty():
					trigger.trigger_cell = encounter.monster_spawns[0].get("cell", Vector2i(10, 3))
				else:
					# Default to room 2 entrance.
					trigger.trigger_cell = Vector2i(10, 3)
			# Position the trigger node at its cell for visual debugging.
			if floor_layer:
				trigger.position = floor_layer.map_to_local(trigger.trigger_cell)


# ---------------------------------------------------------------------------
# Combat support
# ---------------------------------------------------------------------------

## Get references needed by the combat system.
func get_combat_references() -> Dictionary:
	return {
		"floor_layer": floor_layer,
		"wall_layer": wall_layer,
		"pathfinder": pathfinder,
		"character_tokens": character_tokens,
		"controller": self,
	}


## Spawn monster tokens on the grid for a combat encounter.
func spawn_monsters(encounter: CombatEncounterData) -> Array[MonsterToken]:
	var tokens: Array[MonsterToken] = []

	for spawn in encounter.monster_spawns:
		var monster_id: StringName = spawn.get("monster_id", &"")
		var monster: MonsterData = DataRegistry.get_monster(monster_id)
		if monster == null:
			push_warning("GridDungeonController: Unknown monster '%s'" % monster_id)
			continue

		var count: int = spawn.get("count", 1)
		var base_cell: Vector2i = spawn.get("cell", Vector2i.ZERO)

		for i in count:
			var cell: Vector2i = base_cell + Vector2i(i, 0) if count > 1 else base_cell
			var token := MonsterToken.new()
			token.name = "%s_%d" % [monster_id, i]
			token.z_index = 2
			add_child(token)
			token.setup(monster, floor_layer, cell)
			tokens.append(token)
			monster_tokens.append(token)

	return tokens


## Remove all monster tokens from the grid.
func remove_monsters() -> void:
	for token in monster_tokens:
		if is_instance_valid(token):
			token.queue_free()
	monster_tokens.clear()


## Check all encounter triggers after movement.
func _check_encounter_triggers(cell: Vector2i) -> void:
	if GameManager.is_in_combat():
		return
	var triggers_parent: Node = get_node_or_null("EncounterTriggers")
	if triggers_parent == null:
		return
	for child in triggers_parent.get_children():
		if child is CombatEncounterTrigger:
			if child.check_trigger(cell, self):
				return  # One encounter at a time.


## Start a combat encounter. Creates CombatManager and wires everything up.
func start_encounter(encounter: CombatEncounterData) -> void:
	# Spawn monster tokens.
	var m_tokens: Array[MonsterToken] = spawn_monsters(encounter)

	# Create player combatants from character tokens.
	var player_combatants: Array[CombatantData] = []
	for ct in character_tokens:
		if ct.character_data == null:
			# Test token without character data — create a placeholder.
			var placeholder := CharacterData.new()
			placeholder.character_name = "Hero"
			placeholder.level = 1
			placeholder.max_hp = 12
			placeholder.current_hp = 12
			placeholder.speed = 30
			placeholder.ability_scores = AbilityScores.new()
			placeholder.ability_scores.strength = 14
			placeholder.ability_scores.dexterity = 12
			placeholder.ability_scores.constitution = 13
			ct.character_data = placeholder
		var combatant: CombatantData = CombatantData.from_character(ct.character_data)
		combatant.cell = ct.current_cell
		combatant.token = ct
		player_combatants.append(combatant)

	# Create monster combatants.
	var monster_combatants: Array[CombatantData] = []
	for mt in m_tokens:
		var combatant: CombatantData = CombatantData.from_monster(mt.monster_data)
		combatant.cell = mt.current_cell
		combatant.token = mt
		monster_combatants.append(combatant)

	# Create CombatManager.
	combat_manager = CombatManager.new()
	combat_manager.name = "CombatManager"
	combat_manager.floor_layer = floor_layer
	combat_manager.wall_layer = wall_layer
	add_child(combat_manager)

	# Create Monster AI.
	var ai := MonsterAI.new()
	combat_manager.monster_ai = ai

	# Create targeting overlay.
	var overlay := TargetingOverlay.new()
	overlay.name = "TargetingOverlay"
	overlay.z_index = 5
	overlay.setup(floor_layer)
	add_child(overlay)

	# Create damage numbers display.
	var dmg_numbers := DamageNumbers.new()
	dmg_numbers.name = "DamageNumbers"
	dmg_numbers.z_index = 20
	add_child(dmg_numbers)

	# Create CombatGridController.
	combat_grid_controller = CombatGridController.new()
	combat_grid_controller.combat_manager = combat_manager
	combat_grid_controller.floor_layer = floor_layer
	combat_grid_controller.wall_layer = wall_layer
	combat_grid_controller.pathfinder = pathfinder
	combat_grid_controller.targeting_overlay = overlay

	# Create and set up CombatHUD.
	var hud: CanvasLayer = preload("res://ui/combat/combat_hud.tscn").instantiate()
	add_child(hud)
	if hud.has_method("setup"):
		hud.setup(combat_manager, combat_grid_controller)

	# Connect combat end.
	combat_manager.combat_finished.connect(_on_combat_finished)
	combat_manager.player_turn_started.connect(_on_player_turn_started)

	# Start combat.
	combat_manager.start_combat(player_combatants, monster_combatants, encounter)


func _on_combat_finished(players_won: bool) -> void:
	if combat_grid_controller:
		combat_grid_controller.clear_overlays()
		combat_grid_controller = null

	# Award XP if players won.
	if players_won and combat_manager:
		var rewards: Dictionary = CombatRewards.award_xp(
			combat_manager.combatants, combat_manager.encounter_data
		)
		if rewards.get("total_xp", 0) > 0:
			print("Combat won! XP awarded: %d total (%d each)" % [
				rewards.total_xp, rewards.per_character
			])
			for name_str in rewards.get("level_ups", []):
				print("  %s leveled up!" % name_str)
		else:
			print("Combat won!")
	elif not players_won:
		print("Combat lost!")

	# Clean up dead monster tokens.
	remove_monsters()

	# Clean up overlay and damage numbers.
	var overlay: Node = get_node_or_null("TargetingOverlay")
	if overlay:
		overlay.queue_free()
	var dmg_numbers: Node = get_node_or_null("DamageNumbers")
	if dmg_numbers:
		dmg_numbers.queue_free()

	# Clean up CombatHUD.
	for child in get_children():
		if child is CanvasLayer and child.name == "CombatHUD":
			child.queue_free()

	# Clean up CombatManager.
	if combat_manager:
		combat_manager.queue_free()
		combat_manager = null


func _on_player_turn_started(combatant: CombatantData) -> void:
	if combat_grid_controller:
		combat_grid_controller.set_mode_move()

	# Focus camera on the active player's token.
	if combatant.token and combatant.token is CharacterToken:
		_focus_camera_on(combatant.token as Node2D)


func _focus_camera_on(target: Node2D) -> void:
	if camera == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(camera, "position", target.position, 0.3).set_ease(Tween.EASE_OUT)

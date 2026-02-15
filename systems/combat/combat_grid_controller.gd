class_name CombatGridController
extends Node

## Handles combat-mode input on the grid dungeon.
## Active only during combat. Manages move/target selection and delegates to CombatManager.

## Emitted to request UI updates.
signal target_selected(combatant: CombatantData)
signal movement_confirmed(cells_moved: Array[Vector2i])
signal action_requested(action_name: StringName)

## References set by the parent GridDungeonController.
var combat_manager: CombatManager
var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var pathfinder: GridPathfinding
var targeting_overlay: Node2D

## Current input mode.
enum InputMode { MOVE, TARGET_ATTACK, TARGET_SPELL }
var input_mode: InputMode = InputMode.MOVE

## Currently highlighted reachable cells (for movement).
var _reachable_cells: Array[Vector2i] = []

## Currently valid attack targets.
var _valid_targets: Array[CombatantData] = []

## Selected weapon/action for the current attack.
var _selected_weapon: Variant = null


# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if combat_manager == null or not combat_manager.is_active:
		return false
	if not combat_manager.awaiting_player_input:
		return false

	var combatant: CombatantData = combat_manager.current_combatant
	if combatant == null or not combatant.is_player():
		return false

	# Mouse click.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			return _handle_left_click(mb, combatant)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			# Right click cancels targeting.
			if input_mode != InputMode.MOVE:
				set_mode_move()
				return true

	# Keyboard shortcuts.
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		match key.keycode:
			KEY_A:
				action_requested.emit(&"attack")
				return true
			KEY_D:
				action_requested.emit(&"dash")
				return true
			KEY_G:
				action_requested.emit(&"disengage")
				return true
			KEY_O:
				action_requested.emit(&"dodge")
				return true
			KEY_H:
				action_requested.emit(&"hide")
				return true
			KEY_I:
				action_requested.emit(&"use_item")
				return true
			KEY_ENTER, KEY_KP_ENTER:
				action_requested.emit(&"end_turn")
				return true
			KEY_ESCAPE:
				if input_mode != InputMode.MOVE:
					set_mode_move()
					return true

	return false


# ---------------------------------------------------------------------------
# Mode management
# ---------------------------------------------------------------------------

## Switch to movement mode — show reachable cells.
func set_mode_move() -> void:
	input_mode = InputMode.MOVE
	_valid_targets.clear()
	_selected_weapon = null
	_update_movement_overlay()


## Switch to attack targeting mode.
func set_mode_attack(weapon: Variant = null) -> void:
	if combat_manager == null or combat_manager.current_combatant == null:
		return

	var combatant: CombatantData = combat_manager.current_combatant
	_selected_weapon = weapon
	if _selected_weapon == null:
		_selected_weapon = combatant.get_primary_weapon()

	# Determine range.
	var range_normal: int = 5
	var range_long: int = 0
	if _selected_weapon is WeaponData:
		range_normal = (_selected_weapon as WeaponData).range_normal
		range_long = (_selected_weapon as WeaponData).range_long
	elif _selected_weapon is Dictionary:
		range_normal = _selected_weapon.get("reach", _selected_weapon.get("range_normal", 5))
		range_long = _selected_weapon.get("range_long", 0)

	_valid_targets = combat_manager.targeting_system.get_valid_targets(
		combatant, combat_manager.combatants, range_normal, range_long
	)

	input_mode = InputMode.TARGET_ATTACK
	_update_targeting_overlay()


## Refresh the movement overlay for the current combatant.
func refresh_overlays() -> void:
	match input_mode:
		InputMode.MOVE:
			_update_movement_overlay()
		InputMode.TARGET_ATTACK, InputMode.TARGET_SPELL:
			_update_targeting_overlay()


## Clear all overlays.
func clear_overlays() -> void:
	_reachable_cells.clear()
	_valid_targets.clear()
	if targeting_overlay and targeting_overlay.has_method("clear"):
		targeting_overlay.clear()


# ---------------------------------------------------------------------------
# Click handling
# ---------------------------------------------------------------------------

func _handle_left_click(event: InputEventMouseButton, combatant: CombatantData) -> bool:
	var world_pos: Vector2 = _get_world_position(event.position)
	var clicked_cell: Vector2i = floor_layer.local_to_map(world_pos)

	match input_mode:
		InputMode.MOVE:
			return _handle_move_click(clicked_cell, combatant)
		InputMode.TARGET_ATTACK:
			return _handle_attack_click(clicked_cell, combatant)

	return false


func _handle_move_click(target_cell: Vector2i, combatant: CombatantData) -> bool:
	if target_cell == combatant.cell:
		return false
	if target_cell not in _reachable_cells:
		return false

	# Find path and move.
	var max_cells: int = combatant.movement_remaining / 5
	var path: Array[Vector2i] = pathfinder.find_path(combatant.cell, target_cell, max_cells)
	if path.is_empty():
		return false

	var cells_moved: Array[Vector2i] = combat_manager.move_combatant(combatant, path)

	# Animate the token (fire-and-forget, don't await).
	if combatant.token:
		_animate_token_movement(combatant.token, cells_moved, floor_layer)

	movement_confirmed.emit(cells_moved)
	_update_movement_overlay()
	return true


func _animate_token_movement(token: Node2D, cells: Array[Vector2i], floor_layer_ref: TileMapLayer) -> void:
	for cell in cells:
		var target_pos: Vector2 = floor_layer_ref.map_to_local(cell)
		token.animate_move_to(target_pos)
		await token.animation_finished


func _handle_attack_click(target_cell: Vector2i, _combatant: CombatantData) -> bool:
	# Find a valid target at the clicked cell.
	var target: CombatantData = null
	for t in _valid_targets:
		if t.cell == target_cell:
			target = t
			break

	if target == null:
		return false

	# Execute the attack.
	var result: Dictionary = combat_manager.player_attack(target, _selected_weapon)

	# Visual feedback.
	if target.token and result.get("hit", false):
		if target.token.has_method("flash_damage"):
			target.token.flash_damage()
		if target.is_dead and target.token.has_method("play_death"):
			target.token.play_death()

	target_selected.emit(target)

	# If player still has attacks remaining, stay in attack mode.
	if _combatant.attacks_remaining > 0 and _combatant.has_action:
		set_mode_attack(_selected_weapon)
	else:
		set_mode_move()

	return true


# ---------------------------------------------------------------------------
# Overlay updates
# ---------------------------------------------------------------------------

func _update_movement_overlay() -> void:
	if combat_manager == null or combat_manager.current_combatant == null:
		return
	_reachable_cells = combat_manager.get_reachable_cells(combat_manager.current_combatant)
	if targeting_overlay and targeting_overlay.has_method("show_movement"):
		targeting_overlay.show_movement(_reachable_cells)


func _update_targeting_overlay() -> void:
	var target_cells: Array[Vector2i] = []
	for t in _valid_targets:
		target_cells.append(t.cell)
	if targeting_overlay and targeting_overlay.has_method("show_targets"):
		targeting_overlay.show_targets(target_cells)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_world_position(screen_pos: Vector2) -> Vector2:
	var viewport: Viewport = floor_layer.get_viewport()
	if viewport == null:
		return screen_pos
	return floor_layer.get_canvas_transform().affine_inverse() * screen_pos

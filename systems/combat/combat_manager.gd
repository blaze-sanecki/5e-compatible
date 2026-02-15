class_name CombatManager
extends Node

## Central combat orchestrator. Added to the scene tree during combat.
## Manages the turn flow, instantiates subsystems, and coordinates between
## the grid, UI, and AI.

## Emitted when combat state changes.
signal player_turn_started(combatant: CombatantData)
signal monster_turn_started(combatant: CombatantData)
signal combat_finished(players_won: bool)
signal turn_ended(combatant: CombatantData)
signal round_started(round_number: int)

## Subsystems (created on start_combat).
var turn_manager: TurnManager
var damage_system: DamageSystem
var condition_system: ConditionSystem
var action_system: ActionSystem
var targeting_system: TargetingSystem

## All combatants in this encounter.
var combatants: Array[CombatantData] = []

## The currently acting combatant.
var current_combatant: CombatantData = null

## Whether combat is currently active.
var is_active: bool = false

## The encounter data that started this combat (for XP rewards).
var encounter_data: CombatEncounterData = null

## Grid references (set by the caller).
var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var edge_walls: EdgeWallMap

## Monster AI reference (set externally).
var monster_ai: RefCounted = null

## Whether we are waiting for the player to act.
var awaiting_player_input: bool = false


# ---------------------------------------------------------------------------
# Combat lifecycle
# ---------------------------------------------------------------------------

## Start a combat encounter.
func start_combat(player_combatants: Array[CombatantData],
		monster_combatants: Array[CombatantData],
		enc_data: CombatEncounterData = null) -> void:
	if is_active:
		push_warning("CombatManager: Combat already active.")
		return

	encounter_data = enc_data
	combatants.clear()
	combatants.append_array(player_combatants)
	combatants.append_array(monster_combatants)

	# Create subsystems.
	damage_system = DamageSystem.new()
	condition_system = ConditionSystem.new()
	targeting_system = TargetingSystem.new(floor_layer, wall_layer, edge_walls)
	action_system = ActionSystem.new(damage_system, condition_system, targeting_system)
	turn_manager = TurnManager.new()

	# Roll initiative.
	turn_manager.roll_initiative(combatants)
	is_active = true

	GameManager.change_state(GameManager.GameState.COMBAT)
	EventBus.combat_started.emit()
	EventBus.initiative_rolled.emit(_get_initiative_display())

	# Start the first turn.
	_advance_turn()


## End the current combat encounter.
func end_combat() -> void:
	if not is_active:
		return

	var players_won: bool = turn_manager.did_players_win()

	# Sync all player combatants back to their sources.
	for c in combatants:
		if c.is_player():
			c.sync_to_source()

	is_active = false
	awaiting_player_input = false
	current_combatant = null

	GameManager.change_state(GameManager.GameState.EXPLORING)
	EventBus.combat_ended.emit()
	combat_finished.emit(players_won)


## The player has chosen to end their turn.
func end_current_turn() -> void:
	if not awaiting_player_input:
		return
	awaiting_player_input = false
	_finish_turn()


# ---------------------------------------------------------------------------
# Player action API (called by CombatGridController / ActionBar)
# ---------------------------------------------------------------------------

## Player attacks a target with a weapon or unarmed strike.
func player_attack(target: CombatantData, weapon: Variant = null) -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"hit": false, "description": "Not player's turn."}
	if weapon == null:
		weapon = current_combatant.get_primary_weapon()
	return action_system.execute_attack(current_combatant, target, weapon, combatants)


## Player uses the Dash action.
func player_dash() -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"success": false}
	return action_system.execute_dash(current_combatant)


## Player uses the Disengage action.
func player_disengage() -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"success": false}
	return action_system.execute_disengage(current_combatant)


## Player uses the Dodge action.
func player_dodge() -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"success": false}
	return action_system.execute_dodge(current_combatant)


## Player uses the Hide action.
func player_hide() -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"success": false}
	return action_system.execute_hide(current_combatant)


## Player uses the Help action.
func player_help() -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"success": false}
	return action_system.execute_help(current_combatant)


## Player uses a consumable item (costs Action).
func player_use_item(item: ItemData) -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {"success": false, "description": "Not player's turn."}
	return action_system.execute_use_item(current_combatant, item)


## Player makes a death saving throw.
func player_death_save() -> Dictionary:
	if current_combatant == null or not current_combatant.is_player():
		return {}
	return damage_system.make_death_save(current_combatant)


## Move the current combatant along a path. Returns cells actually moved.
## Triggers attacks of opportunity when leaving a threatened cell.
func move_combatant(combatant: CombatantData, path: Array[Vector2i]) -> Array[Vector2i]:
	var moved: Array[Vector2i] = []
	for i in range(1, path.size()):
		var from: Vector2i = combatant.cell
		var to: Vector2i = path[i]
		var diff: Vector2i = to - from
		var is_diagonal: bool = diff.x != 0 and diff.y != 0
		var cost: int = 10 if is_diagonal else 5

		if combatant.movement_remaining < cost:
			break

		# Attack of opportunity check (unless combatant used Disengage).
		if not combatant.is_disengaging:
			_check_opportunity_attacks(combatant, from, to)

		# Stop movement if the combatant was killed by an AoO.
		if combatant.is_dead or combatant.current_hp <= 0:
			break

		combatant.movement_remaining -= cost
		combatant.cell = to
		combatant.has_moved = true
		moved.append(to)

	return moved


## Check if moving from `from_cell` to `to_cell` provokes attacks of opportunity.
## An enemy gets an AoO if the mover leaves their melee reach (adjacent cells).
func _check_opportunity_attacks(mover: CombatantData, from_cell: Vector2i, to_cell: Vector2i) -> void:
	var enemies: Array[CombatantData] = get_enemies_of(mover)
	for enemy in enemies:
		if enemy.is_dead or not enemy.is_alive():
			continue
		if not enemy.has_reaction:
			continue
		if condition_system.is_incapacitated(enemy):
			continue

		# Was the enemy adjacent to the mover's old position?
		var old_dist: int = absi(from_cell.x - enemy.cell.x) + absi(from_cell.y - enemy.cell.y)
		var chebyshev_old: int = maxi(absi(from_cell.x - enemy.cell.x), absi(from_cell.y - enemy.cell.y))
		if chebyshev_old > 1:
			continue  # Enemy wasn't in melee range.

		# Is the enemy still adjacent after the move? If so, no AoO.
		var chebyshev_new: int = maxi(absi(to_cell.x - enemy.cell.x), absi(to_cell.y - enemy.cell.y))
		if chebyshev_new <= 1:
			continue  # Still in melee range — no AoO.

		# Provokes AoO! Enemy uses reaction to attack.
		enemy.has_reaction = false
		var weapon: Variant = enemy.get_primary_weapon()
		if weapon == null:
			continue

		var result: Dictionary = action_system.execute_opportunity_attack(enemy, mover, weapon, combatants)
		print("AoO: %s" % result.get("description", ""))


## Get reachable cells for the current combatant.
func get_reachable_cells(combatant: CombatantData) -> Array[Vector2i]:
	if floor_layer == null or wall_layer == null:
		return []
	var pathfinder := GridPathfinding.new(floor_layer, wall_layer, edge_walls)
	var max_cells: int = combatant.movement_remaining / 5
	return pathfinder.get_reachable_cells(combatant.cell, max_cells)


# ---------------------------------------------------------------------------
# Turn flow (internal)
# ---------------------------------------------------------------------------

func _advance_turn() -> void:
	# Check if combat is over.
	if turn_manager.is_combat_over():
		end_combat()
		return

	var prev_round: int = turn_manager.current_round
	current_combatant = turn_manager.next_turn()

	if current_combatant == null:
		end_combat()
		return

	# New round notification.
	if turn_manager.current_round > prev_round:
		EventBus.combat_round_started.emit(turn_manager.current_round)
		round_started.emit(turn_manager.current_round)

	# Process start-of-turn conditions.
	condition_system.process_start_of_turn(current_combatant)

	EventBus.turn_started.emit(current_combatant.source)

	# Check if the combatant is unconscious (death save instead of normal turn).
	if current_combatant.is_unconscious():
		if current_combatant.is_player():
			awaiting_player_input = true
			player_turn_started.emit(current_combatant)
		else:
			_finish_turn()
		return

	if current_combatant.is_player():
		awaiting_player_input = true
		player_turn_started.emit(current_combatant)
	else:
		monster_turn_started.emit(current_combatant)
		# Execute monster AI.
		await _execute_monster_turn(current_combatant)
		_finish_turn()


func _finish_turn() -> void:
	if current_combatant == null:
		return

	# Process end-of-turn conditions.
	condition_system.process_end_of_turn(current_combatant)

	EventBus.turn_ended.emit(current_combatant.source)
	turn_ended.emit(current_combatant)

	# Small delay between turns for readability.
	await get_tree().create_timer(0.3).timeout

	_advance_turn()


func _execute_monster_turn(combatant: CombatantData) -> void:
	if monster_ai == null:
		# No AI — just skip.
		return

	# Add a small delay before the monster acts for visual clarity.
	await get_tree().create_timer(0.4).timeout

	monster_ai.execute_turn(combatant, combatants, self)

	# Wait for token animations.
	await get_tree().create_timer(0.3).timeout


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_initiative_display() -> Array:
	var order: Array = []
	for c in turn_manager.combatants:
		order.append({
			"name": c.display_name,
			"initiative": c.initiative,
			"is_player": c.is_player(),
		})
	return order


## Get a combatant at a specific grid cell.
func get_combatant_at(cell: Vector2i) -> CombatantData:
	for c in combatants:
		if not c.is_dead and c.cell == cell:
			return c
	return null


## Get all living enemy combatants relative to a given combatant.
func get_enemies_of(combatant: CombatantData) -> Array[CombatantData]:
	var enemies: Array[CombatantData] = []
	for c in combatants:
		if c.is_dead or c == combatant:
			continue
		if c.type != combatant.type:
			enemies.append(c)
	return enemies


## Get all living ally combatants (same type, not self).
func get_allies_of(combatant: CombatantData) -> Array[CombatantData]:
	var allies: Array[CombatantData] = []
	for c in combatants:
		if c.is_dead or c == combatant:
			continue
		if c.type == combatant.type:
			allies.append(c)
	return allies

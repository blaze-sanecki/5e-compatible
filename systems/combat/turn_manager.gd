class_name TurnManager
extends RefCounted

## Manages initiative order, turn progression, and round counting.

## All combatants in initiative order (highest first).
var combatants: Array[CombatantData] = []

## Index of the current combatant in the order.
var current_index: int = -1

## Current round number (starts at 1).
var current_round: int = 0


# ---------------------------------------------------------------------------
# Initiative
# ---------------------------------------------------------------------------

## Roll initiative for all combatants and sort by result (descending).
func roll_initiative(all_combatants: Array[CombatantData]) -> void:
	combatants = all_combatants

	for c in combatants:
		var mod: int = c.get_initiative_modifier()
		var roll := DiceRoller.roll_d20(mod)
		c.initiative = roll.total

	# Sort descending by initiative; break ties by DEX modifier.
	combatants.sort_custom(func(a: CombatantData, b: CombatantData) -> bool:
		if a.initiative != b.initiative:
			return a.initiative > b.initiative
		return a.get_modifier(&"dexterity") > b.get_modifier(&"dexterity")
	)

	current_index = -1
	current_round = 0


## Get the current combatant whose turn it is.
func get_current_combatant() -> CombatantData:
	if current_index < 0 or current_index >= combatants.size():
		return null
	return combatants[current_index]


## Advance to the next living combatant's turn. Returns the combatant or null if combat is over.
func next_turn() -> CombatantData:
	if combatants.is_empty():
		return null

	var attempts: int = 0
	var max_attempts: int = combatants.size() + 1

	while attempts < max_attempts:
		current_index += 1

		# New round
		if current_index >= combatants.size():
			current_index = 0
			current_round += 1

		var combatant: CombatantData = combatants[current_index]

		# Skip dead combatants.
		if combatant.is_dead:
			attempts += 1
			continue

		# Prepare the combatant for their turn.
		combatant.start_turn()
		return combatant

		attempts += 1

	return null


## Remove a combatant from the order (e.g., fled, banished).
func remove_combatant(combatant: CombatantData) -> void:
	var idx: int = combatants.find(combatant)
	if idx == -1:
		return
	combatants.remove_at(idx)
	if current_index >= idx and current_index > 0:
		current_index -= 1


## Check if all monsters or all players are defeated.
func is_combat_over() -> bool:
	var players_alive: bool = false
	var monsters_alive: bool = false
	for c in combatants:
		if c.is_dead:
			continue
		if c.is_player() and c.current_hp > 0:
			players_alive = true
		elif c.is_monster() and c.current_hp > 0:
			monsters_alive = true
	return not players_alive or not monsters_alive


## Check if the players won (all monsters dead).
func did_players_win() -> bool:
	for c in combatants:
		if c.is_monster() and not c.is_dead and c.current_hp > 0:
			return false
	return true


## Get the initiative order for display.
func get_initiative_order() -> Array[CombatantData]:
	return combatants


## Get all living combatants of a given type.
func get_living(combatant_type: CombatantData.CombatantType) -> Array[CombatantData]:
	var result: Array[CombatantData] = []
	for c in combatants:
		if c.type == combatant_type and not c.is_dead and c.current_hp > 0:
			result.append(c)
	return result

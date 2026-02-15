class_name ConditionSystem
extends RefCounted

## Manages condition application, removal, and queries for the combat system.
## Conditions are stored by ID on each CombatantData.


## Apply a condition to a combatant. Returns false if immune.
func apply_condition(combatant: CombatantData, condition_id: StringName, _source: CombatantData = null) -> bool:
	# Check condition immunity (monsters only).
	if combatant.is_monster():
		var monster: MonsterData = combatant.source as MonsterData
		if monster and condition_id in monster.condition_immunities:
			return false

	# Don't double-apply.
	if combatant.has_condition(condition_id):
		return false

	combatant.conditions.append(condition_id)
	EventBus.condition_applied.emit(combatant.source, condition_id)
	return true


## Remove a condition from a combatant.
func remove_condition(combatant: CombatantData, condition_id: StringName) -> void:
	if not combatant.has_condition(condition_id):
		return
	combatant.conditions.erase(condition_id)
	EventBus.condition_removed.emit(combatant.source, condition_id)


## Process conditions at the start of a combatant's turn.
## Some conditions allow a save at start of turn.
func process_start_of_turn(combatant: CombatantData) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var to_remove: Array[StringName] = []

	for cond_id in combatant.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		if cond_data.ends_on == &"start_of_turn" and cond_data.save_ability != &"":
			var save := RulesEngine.resolve_saving_throw(
				combatant.source, cond_data.save_dc, cond_data.save_ability
			)
			var entry: Dictionary = {
				"condition": cond_id,
				"save_success": save.success,
				"roll": save.roll_result.total if save.roll_result else 0,
			}
			results.append(entry)
			if save.success:
				to_remove.append(cond_id)

	for cond_id in to_remove:
		remove_condition(combatant, cond_id)

	return results


## Process conditions at the end of a combatant's turn.
func process_end_of_turn(combatant: CombatantData) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var to_remove: Array[StringName] = []

	for cond_id in combatant.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		if cond_data.ends_on == &"end_of_turn" and cond_data.save_ability != &"":
			var save := RulesEngine.resolve_saving_throw(
				combatant.source, cond_data.save_dc, cond_data.save_ability
			)
			var entry: Dictionary = {
				"condition": cond_id,
				"save_success": save.success,
				"roll": save.roll_result.total if save.roll_result else 0,
			}
			results.append(entry)
			if save.success:
				to_remove.append(cond_id)

	for cond_id in to_remove:
		remove_condition(combatant, cond_id)

	return results


## Check if a combatant has advantage on attack rolls due to conditions.
func has_attack_advantage(attacker: CombatantData, target: CombatantData) -> bool:
	# Attacker conditions giving advantage
	if attacker.has_condition(&"invisible"):
		return true

	# Target conditions giving attacker advantage
	for cond_id in target.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		for effect in cond_data.effects:
			if effect.type == &"advantage" and effect.on == &"attack_rolls_against":
				return true

	return false


## Check if a combatant has disadvantage on attack rolls due to conditions.
func has_attack_disadvantage(attacker: CombatantData, target: CombatantData) -> bool:
	# Attacker conditions giving disadvantage
	for cond_id in attacker.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		for effect in cond_data.effects:
			if effect.type == &"disadvantage" and effect.on == &"attack_rolls":
				return true

	# Target dodging
	if target.is_dodging and target.current_hp > 0:
		return true

	# Target invisible
	if target.has_condition(&"invisible"):
		return true

	return false


## Check if attacks against a downed target auto-crit (within 5 ft).
func is_auto_crit(target: CombatantData, distance_ft: int) -> bool:
	if distance_ft > 5:
		return false
	for cond_id in target.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		for effect in cond_data.effects:
			if effect.type == &"auto_crit" and effect.on == &"melee_attacks_against":
				return true
	return false


## Check if a combatant is incapacitated (can't take actions).
func is_incapacitated(combatant: CombatantData) -> bool:
	for cond_id in combatant.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		for effect in cond_data.effects:
			if effect.type == &"incapacitated":
				return true
			if effect.type == &"cant_act" and effect.on == &"actions":
				return true
	return false


## Check if a combatant's speed is reduced to 0 by conditions.
func is_speed_zero(combatant: CombatantData) -> bool:
	for cond_id in combatant.conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data == null:
			continue
		for effect in cond_data.effects:
			if effect.type == &"speed" and effect.value == 0:
				return true
	return false

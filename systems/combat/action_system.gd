class_name ActionSystem
extends RefCounted

## Validates and executes combat actions following 5e SRD rules.
## Tracks action economy and handles the Attack, Dash, Disengage, Dodge,
## Hide, and Help actions.

var _damage_system: DamageSystem
var _condition_system: ConditionSystem
var _targeting_system: TargetingSystem


func _init(damage_sys: DamageSystem, condition_sys: ConditionSystem, targeting_sys: TargetingSystem) -> void:
	_damage_system = damage_sys
	_condition_system = condition_sys
	_targeting_system = targeting_sys


# ---------------------------------------------------------------------------
# Action validation
# ---------------------------------------------------------------------------

## Check if a combatant can take the Attack action.
func can_attack(combatant: CombatantData) -> bool:
	return combatant.has_action and combatant.is_alive() and not _condition_system.is_incapacitated(combatant)


## Check if a combatant can take the Dash action.
func can_dash(combatant: CombatantData) -> bool:
	return combatant.has_action and combatant.is_alive() and not _condition_system.is_incapacitated(combatant)


## Check if a combatant can Disengage.
func can_disengage(combatant: CombatantData) -> bool:
	return combatant.has_action and combatant.is_alive() and not _condition_system.is_incapacitated(combatant)


## Check if a combatant can Dodge.
func can_dodge(combatant: CombatantData) -> bool:
	return combatant.has_action and combatant.is_alive() and not _condition_system.is_incapacitated(combatant)


## Check if a combatant can Hide.
func can_hide(combatant: CombatantData) -> bool:
	return combatant.has_action and combatant.is_alive() and not _condition_system.is_incapacitated(combatant)


## Check if a combatant can use the Help action.
func can_help(combatant: CombatantData) -> bool:
	return combatant.has_action and combatant.is_alive() and not _condition_system.is_incapacitated(combatant)


## Check if a combatant can use a consumable item (costs Action).
func can_use_item(combatant: CombatantData) -> bool:
	if not combatant.has_action or not combatant.is_alive():
		return false
	if _condition_system.is_incapacitated(combatant):
		return false
	if not combatant.is_player():
		return false
	# Check if they have any consumable items.
	return not get_consumable_items(combatant).is_empty()


## Get all consumable items in a player combatant's inventory.
func get_consumable_items(combatant: CombatantData) -> Array[ItemData]:
	var items: Array[ItemData] = []
	if not combatant.is_player() or combatant.source == null:
		return items
	var character: CharacterData = combatant.source as CharacterData
	if character == null:
		return items
	for entry in character.inventory:
		if entry is InventoryEntry and entry.item is ItemData:
			var item: ItemData = entry.item as ItemData
			if item.item_type == &"consumable" and not item.effects.is_empty():
				items.append(item)
		elif entry is ItemData:
			var item: ItemData = entry as ItemData
			if item.item_type == &"consumable" and not item.effects.is_empty():
				items.append(item)
	return items


# ---------------------------------------------------------------------------
# Execute: Attack
# ---------------------------------------------------------------------------

## Execute a melee or ranged attack from attacker to target.
## Returns a result dictionary with hit/miss/damage info.
func execute_attack(attacker: CombatantData, target: CombatantData,
		weapon_or_action: Variant, all_combatants: Array[CombatantData]) -> Dictionary:
	var result: Dictionary = {
		"hit": false,
		"critical": false,
		"damage": 0,
		"damage_type": &"bludgeoning",
		"attack_roll": 0,
		"target_ac": target.get_ac(),
		"description": "",
	}

	if not can_attack(attacker):
		result.description = "%s cannot attack." % attacker.display_name
		return result

	# Determine attack properties.
	var attack_bonus: int = 0
	var damage_notation: String = "1d4"
	var damage_type: StringName = &"bludgeoning"
	var range_normal: int = 5
	var is_melee: bool = true
	var weapon_name: String = "Unarmed Strike"

	if weapon_or_action is WeaponData:
		var weapon: WeaponData = weapon_or_action as WeaponData
		weapon_name = weapon.display_name
		damage_notation = weapon.damage.to_notation()
		damage_type = weapon.damage.damage_type
		range_normal = weapon.range_normal
		is_melee = weapon.is_melee()

		# Attack modifier: proficiency + ability mod.
		var prof: int = attacker.get_proficiency_bonus()
		var ability_mod: int = 0
		if weapon.has_property(&"finesse"):
			# Use the higher of STR or DEX.
			var str_mod: int = attacker.get_modifier(&"strength")
			var dex_mod: int = attacker.get_modifier(&"dexterity")
			ability_mod = maxi(str_mod, dex_mod)
		elif is_melee:
			ability_mod = attacker.get_modifier(&"strength")
		else:
			ability_mod = attacker.get_modifier(&"dexterity")
		attack_bonus = prof + ability_mod
	elif weapon_or_action is MonsterAction:
		var action: MonsterAction = weapon_or_action
		weapon_name = action.name
		attack_bonus = action.attack_bonus
		damage_notation = action.damage
		damage_type = action.damage_type if action.damage_type != &"" else &"bludgeoning"
		range_normal = action.reach if action.reach > 0 else action.range_normal
		is_melee = action.type == &"melee_attack" or action.type == &""

	# Advantage/disadvantage from conditions.
	var advantage: bool = _condition_system.has_attack_advantage(attacker, target)
	var disadvantage: bool = _condition_system.has_attack_disadvantage(attacker, target)

	# Long range disadvantage.
	if not is_melee and _targeting_system.is_long_range(attacker, target, range_normal):
		disadvantage = true

	# Prone target: advantage if melee within 5ft, disadvantage if ranged.
	if target.has_condition(&"prone"):
		var dist: int = _targeting_system.combatant_distance_ft(attacker, target)
		if dist <= 5:
			advantage = true
		else:
			disadvantage = true

	# Cover bonus to AC.
	var occupied: Array[Vector2i] = _targeting_system.get_occupied_cells(all_combatants)
	var cover_bonus: int = _targeting_system.calculate_cover(attacker.cell, target.cell, occupied)

	# Auto-crit check (paralyzed, unconscious within 5 ft).
	var dist_ft: int = _targeting_system.combatant_distance_ft(attacker, target)
	var auto_crit: bool = _condition_system.is_auto_crit(target, dist_ft)

	# Roll the attack.
	var d20 := DiceRoller.attack_roll(attack_bonus, advantage, disadvantage)
	result.attack_roll = d20.total

	var effective_ac: int = target.get_ac() + cover_bonus

	if d20.is_fumble:
		result.hit = false
	elif d20.is_critical or auto_crit:
		result.hit = true
		result.critical = true
	else:
		result.hit = d20.total >= effective_ac

	# Roll damage if hit.
	if result.hit:
		var dmg := DiceRoller.roll(damage_notation)
		var total_damage: int = dmg.total

		# Add ability modifier to damage for player weapons.
		if weapon_or_action is WeaponData:
			var weapon: WeaponData = weapon_or_action as WeaponData
			var ability_mod: int = 0
			if weapon.has_property(&"finesse"):
				ability_mod = maxi(attacker.get_modifier(&"strength"), attacker.get_modifier(&"dexterity"))
			elif weapon.is_melee():
				ability_mod = attacker.get_modifier(&"strength")
			else:
				ability_mod = attacker.get_modifier(&"dexterity")
			total_damage += ability_mod

		# Critical hit: roll damage dice again.
		if result.critical:
			var crit_extra := DiceRoller.roll(damage_notation)
			total_damage += crit_extra.total

		total_damage = maxi(total_damage, 0)
		result.damage = total_damage
		result.damage_type = damage_type

		# Apply damage.
		if target.current_hp <= 0 and target.is_player():
			_damage_system.damage_downed_player(target, result.critical)
		else:
			_damage_system.apply_damage(target, total_damage, damage_type)

		result.description = "%s hits %s with %s for %d %s damage%s!" % [
			attacker.display_name, target.display_name, weapon_name,
			total_damage, damage_type,
			" (CRITICAL)" if result.critical else "",
		]

		# Check for special effects (e.g., wolf's knockdown).
		if weapon_or_action is MonsterAction:
			var action: MonsterAction = weapon_or_action
			if action.save_dc > 0 and action.save_effect != "":
				_apply_save_effect(target, action)
	else:
		result.description = "%s misses %s with %s." % [
			attacker.display_name, target.display_name, weapon_name,
		]

	# Consume attack.
	attacker.attacks_remaining -= 1
	if attacker.attacks_remaining <= 0:
		attacker.has_action = false

	EventBus.action_performed.emit(attacker.source, {
		"type": "attack", "weapon": weapon_name,
		"hit": result.hit, "damage": result.damage,
	})

	return result


# ---------------------------------------------------------------------------
# Execute: Attack of Opportunity (reaction)
# ---------------------------------------------------------------------------

## Execute an attack of opportunity. Uses the attacker's reaction, not action.
func execute_opportunity_attack(attacker: CombatantData, target: CombatantData,
		weapon_or_action: Variant, all_combatants: Array[CombatantData]) -> Dictionary:
	# Save and restore action state — AoO doesn't consume the action.
	var saved_has_action: bool = attacker.has_action
	var saved_attacks: int = attacker.attacks_remaining
	attacker.has_action = true
	attacker.attacks_remaining = 1

	var result: Dictionary = execute_attack(attacker, target, weapon_or_action, all_combatants)

	# Restore action economy (AoO only costs reaction, already consumed by caller).
	attacker.has_action = saved_has_action
	attacker.attacks_remaining = saved_attacks

	# Tag the result as an opportunity attack.
	result["is_opportunity_attack"] = true
	if result.hit:
		result.description = "Attack of Opportunity! " + result.description
	else:
		result.description = "Attack of Opportunity! " + result.description

	return result


# ---------------------------------------------------------------------------
# Execute: Dash
# ---------------------------------------------------------------------------

func execute_dash(combatant: CombatantData) -> Dictionary:
	if not can_dash(combatant):
		return {"success": false, "description": "%s cannot Dash." % combatant.display_name}

	combatant.movement_remaining += combatant.get_speed()
	combatant.has_action = false

	var desc: String = "%s takes the Dash action (movement doubled)." % combatant.display_name
	EventBus.action_performed.emit(combatant.source, {"type": "dash"})
	return {"success": true, "description": desc}


# ---------------------------------------------------------------------------
# Execute: Disengage
# ---------------------------------------------------------------------------

func execute_disengage(combatant: CombatantData) -> Dictionary:
	if not can_disengage(combatant):
		return {"success": false, "description": "%s cannot Disengage." % combatant.display_name}

	combatant.is_disengaging = true
	combatant.has_action = false

	var desc: String = "%s takes the Disengage action." % combatant.display_name
	EventBus.action_performed.emit(combatant.source, {"type": "disengage"})
	return {"success": true, "description": desc}


# ---------------------------------------------------------------------------
# Execute: Dodge
# ---------------------------------------------------------------------------

func execute_dodge(combatant: CombatantData) -> Dictionary:
	if not can_dodge(combatant):
		return {"success": false, "description": "%s cannot Dodge." % combatant.display_name}

	combatant.is_dodging = true
	combatant.has_action = false

	var desc: String = "%s takes the Dodge action." % combatant.display_name
	EventBus.action_performed.emit(combatant.source, {"type": "dodge"})
	return {"success": true, "description": desc}


# ---------------------------------------------------------------------------
# Execute: Hide
# ---------------------------------------------------------------------------

func execute_hide(combatant: CombatantData) -> Dictionary:
	if not can_hide(combatant):
		return {"success": false, "description": "%s cannot Hide." % combatant.display_name}

	# Stealth check.
	var stealth_mod: int = combatant.get_modifier(&"dexterity")
	if combatant.is_player():
		stealth_mod = RulesEngine.get_skill_modifier(combatant.source, &"stealth")
	var roll := DiceRoller.ability_check(stealth_mod)

	combatant.is_hidden = true
	combatant.has_action = false

	var desc: String = "%s takes the Hide action (Stealth: %d)." % [combatant.display_name, roll.total]
	EventBus.action_performed.emit(combatant.source, {"type": "hide", "stealth_roll": roll.total})
	return {"success": true, "description": desc, "stealth_roll": roll.total}


# ---------------------------------------------------------------------------
# Execute: Help
# ---------------------------------------------------------------------------

func execute_help(combatant: CombatantData) -> Dictionary:
	if not can_help(combatant):
		return {"success": false, "description": "%s cannot Help." % combatant.display_name}

	combatant.has_action = false

	var desc: String = "%s takes the Help action." % combatant.display_name
	EventBus.action_performed.emit(combatant.source, {"type": "help"})
	return {"success": true, "description": desc}


# ---------------------------------------------------------------------------
# Execute: Use Item
# ---------------------------------------------------------------------------

## Use a consumable item from inventory. Costs the Action for the turn.
func execute_use_item(combatant: CombatantData, item: ItemData) -> Dictionary:
	if not can_use_item(combatant):
		return {"success": false, "description": "%s cannot use an item." % combatant.display_name}

	var character: CharacterData = combatant.source as CharacterData
	if character == null:
		return {"success": false, "description": "No character data."}

	var result: Dictionary = InventorySystem.use_item(character, item)
	if not result.get("success", false):
		return {"success": false, "description": result.get("message", "Cannot use item.")}

	# Sync combatant HP from the character data (potion may have healed).
	combatant.current_hp = character.current_hp
	combatant.temp_hp = character.temp_hp

	# Sync conditions.
	combatant.conditions.clear()
	for cond in character.conditions:
		combatant.conditions.append(cond)

	combatant.has_action = false

	# Build description.
	var desc: String = "%s uses %s." % [combatant.display_name, item.display_name]
	var effects: Array = result.get("effects", [])
	for eff in effects:
		match str(eff.get("type", "")):
			"heal":
				desc += " Healed %d HP." % eff.get("amount", 0)
			"remove_condition":
				desc += " Removed %s." % eff.get("condition", "")

	EventBus.action_performed.emit(combatant.source, {"type": "use_item", "item": item.display_name})
	return {"success": true, "description": desc, "effects": effects}


# ---------------------------------------------------------------------------
# Execute: End Turn
# ---------------------------------------------------------------------------

func execute_end_turn(combatant: CombatantData) -> Dictionary:
	combatant.has_action = false
	combatant.has_bonus_action = false
	var desc: String = "%s ends their turn." % combatant.display_name
	return {"success": true, "description": desc}


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _apply_save_effect(target: CombatantData, action: MonsterAction) -> void:
	var dc: int = action.save_dc
	var ability: StringName = action.save_ability if action.save_ability != &"" else &"strength"
	var effect: String = action.save_effect

	var save := RulesEngine.resolve_saving_throw(target.source, dc, ability)
	if not save.success and effect != "":
		_condition_system.apply_condition(target, StringName(effect))

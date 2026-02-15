class_name DamageSystem
extends RefCounted

## Handles all damage application, healing, death saves, and HP management
## following 5e SRD rules.


## Apply damage to a combatant, respecting temp HP, resistances, vulnerabilities,
## and immunities. Returns the actual damage dealt.
func apply_damage(target: CombatantData, amount: int, damage_type: StringName) -> int:
	if target.is_dead:
		return 0

	var final_amount: int = _apply_damage_modifiers(target, amount, damage_type)

	# Absorb with temp HP first.
	if target.temp_hp > 0:
		if final_amount <= target.temp_hp:
			target.temp_hp -= final_amount
			target.sync_to_source()
			EventBus.character_damaged.emit(target.source, final_amount, damage_type)
			return final_amount
		else:
			final_amount -= target.temp_hp
			target.temp_hp = 0

	target.current_hp -= final_amount

	# Check for instant death (massive damage).
	if target.current_hp < 0 and absi(target.current_hp) >= target.max_hp:
		target.current_hp = 0
		target.is_dead = true
		target.sync_to_source()
		EventBus.character_damaged.emit(target.source, final_amount, damage_type)
		EventBus.character_died.emit(target.source)
		return final_amount

	# Drop to 0 HP.
	if target.current_hp <= 0:
		target.current_hp = 0
		if target.is_monster():
			target.is_dead = true
			EventBus.character_died.emit(target.source)
		else:
			# Player falls unconscious — death saves begin.
			target.death_save_successes = 0
			target.death_save_failures = 0
			if not target.has_condition(&"unconscious"):
				target.conditions.append(&"unconscious")
				EventBus.condition_applied.emit(target.source, &"unconscious")

	target.sync_to_source()
	EventBus.character_damaged.emit(target.source, final_amount, damage_type)

	# Concentration check on taking damage.
	if target.is_concentrating and target.current_hp > 0:
		_concentration_check(target, final_amount)

	return final_amount


## Heal a combatant. Cannot exceed max HP. Returns actual healing done.
func apply_healing(target: CombatantData, amount: int) -> int:
	if target.is_dead:
		return 0

	# Healing a creature at 0 HP restores consciousness.
	var was_unconscious: bool = target.current_hp <= 0

	var old_hp: int = target.current_hp
	target.current_hp = mini(target.current_hp + amount, target.max_hp)
	var healed: int = target.current_hp - old_hp

	if was_unconscious and target.current_hp > 0 and target.is_player():
		target.death_save_successes = 0
		target.death_save_failures = 0
		if target.has_condition(&"unconscious"):
			target.conditions.erase(&"unconscious")
			EventBus.condition_removed.emit(target.source, &"unconscious")

	target.sync_to_source()
	EventBus.character_healed.emit(target.source, healed)
	return healed


## Apply temporary hit points (they don't stack, take the higher).
func apply_temp_hp(target: CombatantData, amount: int) -> void:
	target.temp_hp = maxi(target.temp_hp, amount)
	target.sync_to_source()


## Make a death saving throw. Returns the result dictionary.
func make_death_save(combatant: CombatantData) -> Dictionary:
	var roll := DiceRoller.roll_d20()
	var result: Dictionary = {
		"natural_roll": roll.natural_roll,
		"total": roll.total,
		"success": false,
		"stabilized": false,
		"revived": false,
		"died": false,
	}

	if roll.natural_roll == 20:
		# Nat 20: regain 1 HP.
		result.success = true
		result.revived = true
		combatant.current_hp = 1
		combatant.death_save_successes = 0
		combatant.death_save_failures = 0
		if combatant.has_condition(&"unconscious"):
			combatant.conditions.erase(&"unconscious")
			EventBus.condition_removed.emit(combatant.source, &"unconscious")
	elif roll.natural_roll == 1:
		# Nat 1: two failures.
		combatant.death_save_failures += 2
	elif roll.total >= 10:
		result.success = true
		combatant.death_save_successes += 1
	else:
		combatant.death_save_failures += 1

	# Check for death or stabilization.
	if combatant.death_save_failures >= 3:
		combatant.is_dead = true
		result.died = true
		EventBus.character_died.emit(combatant.source)
	elif combatant.death_save_successes >= 3:
		result.stabilized = true
		# Stabilized but still at 0 HP.

	combatant.sync_to_source()
	EventBus.death_save_made.emit(combatant.source, result)
	return result


## Damage a downed (0 HP) player — each hit counts as a failed death save.
## A critical hit counts as two failures.
func damage_downed_player(combatant: CombatantData, is_crit: bool) -> void:
	if not combatant.is_player() or combatant.current_hp > 0:
		return
	combatant.death_save_failures += 2 if is_crit else 1
	if combatant.death_save_failures >= 3:
		combatant.is_dead = true
		EventBus.character_died.emit(combatant.source)
	combatant.sync_to_source()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _apply_damage_modifiers(target: CombatantData, amount: int, damage_type: StringName) -> int:
	var monster: MonsterData = target.source as MonsterData
	if monster == null:
		return amount

	# Immunity.
	if damage_type in monster.damage_immunities:
		return 0

	# Resistance (half damage).
	if damage_type in monster.damage_resistances:
		@warning_ignore("integer_division")
		return amount / 2

	# Vulnerability (double damage).
	if damage_type in monster.damage_vulnerabilities:
		return amount * 2

	return amount


func _concentration_check(combatant: CombatantData, damage: int) -> void:
	var dc: int = maxi(10, damage / 2)
	var save_result := RulesEngine.resolve_saving_throw(
		combatant.source, dc, &"constitution"
	)
	if not save_result.success:
		combatant.is_concentrating = false
		combatant.concentration_spell = null
		if combatant.is_player():
			combatant.source.concentration_spell = null
		EventBus.concentration_broken.emit(combatant.source)

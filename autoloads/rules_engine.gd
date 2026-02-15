## Central 5e rules arbiter.
##
## Registered as an autoload singleton. Handles AC calculation, attack
## resolution, saving throws, skill checks, and all the core 5e math.
##
## Character parameters are typed as CharacterData. Combat functions that
## accept both player and monster sources use CombatantData's uniform interface.
extends Node

# ===========================================================================
# Inner classes
# ===========================================================================

## The outcome of an attack roll + damage resolution.
class AttackResult:
	var hit: bool = false
	var critical: bool = false
	var damage_total: int = 0
	var damage_rolls: Array = []
	var attack_roll  # DiceRoller.D20Result


## The outcome of a saving throw.
class SaveResult:
	var success: bool = false
	var roll_result  # DiceRoller.D20Result
	var dc: int = 0


# ===========================================================================
# Skill -> Ability mapping (all 18 5e skills)
# ===========================================================================

const SKILL_ABILITIES: Dictionary = {
	&"acrobatics": &"dexterity",
	&"animal_handling": &"wisdom",
	&"arcana": &"intelligence",
	&"athletics": &"strength",
	&"deception": &"charisma",
	&"history": &"intelligence",
	&"insight": &"wisdom",
	&"intimidation": &"charisma",
	&"investigation": &"intelligence",
	&"medicine": &"wisdom",
	&"nature": &"intelligence",
	&"perception": &"wisdom",
	&"performance": &"charisma",
	&"persuasion": &"charisma",
	&"religion": &"intelligence",
	&"sleight_of_hand": &"dexterity",
	&"stealth": &"dexterity",
	&"survival": &"wisdom",
}


# ===========================================================================
# Core math helpers
# ===========================================================================

## Convert a raw ability score to its modifier: floor((score - 10) / 2).
func get_modifier(score: int) -> int:
	return int(floor((score - 10) / 2.0))


## Return the proficiency bonus for a given character level.
func get_proficiency_bonus(level: int) -> int:
	return int(floor((level - 1) / 4.0)) + 2


# ===========================================================================
# AC calculations
# ===========================================================================

## Calculate a character's Armor Class.
##
## Falls back to unarmored defense (10 + DEX mod) when no armor is equipped.
func calculate_ac(character: CharacterData) -> int:
	var dex_mod: int = character.get_modifier(&"dexterity")
	var ac: int = 10 + dex_mod  # Unarmored default

	if character.equipped_armor != null:
		var armor: ArmorData = character.equipped_armor as ArmorData
		if armor:
			ac = armor.calculate_ac(dex_mod)

	if character.equipped_shield != null:
		var shield: ArmorData = character.equipped_shield as ArmorData
		var shield_bonus: int = shield.base_ac if shield else 2
		ac += shield_bonus

	return ac


## Spell save DC = 8 + proficiency bonus + spellcasting ability modifier.
func calculate_spell_dc(character: CharacterData) -> int:
	var prof: int = get_proficiency_bonus(character.level)
	var casting_ability: StringName = _get_casting_ability(character)
	var ability_mod: int = character.get_modifier(casting_ability)
	return 8 + prof + ability_mod


## Spell attack modifier = proficiency bonus + spellcasting ability modifier.
func calculate_spell_attack(character: CharacterData) -> int:
	var prof: int = get_proficiency_bonus(character.level)
	var casting_ability: StringName = _get_casting_ability(character)
	var ability_mod: int = character.get_modifier(casting_ability)
	return prof + ability_mod


# ===========================================================================
# Attack resolution
# ===========================================================================

## Resolve a full attack: roll to hit, compare to target AC, then roll damage.
##
## [code]weapon_or_spell[/code] is expected to expose [code]damage_dice[/code]
## (String notation like "1d8") and optionally [code]damage_modifier[/code].
func resolve_attack(
	attacker,
	target,
	weapon_or_spell,
	advantage: bool = false,
	disadvantage: bool = false,
) -> AttackResult:
	var result := AttackResult.new()

	# Determine attack modifier.
	var attack_mod: int = 0
	if weapon_or_spell.has_method("get_attack_modifier"):
		attack_mod = weapon_or_spell.get_attack_modifier(attacker)
	else:
		# Default: proficiency + STR mod (melee) -- callers can customise.
		var prof: int = get_proficiency_bonus(attacker.level)
		var str_mod: int = attacker.get_modifier(&"strength")
		attack_mod = prof + str_mod

	# Roll to hit.
	var d20_result = DiceRoller.attack_roll(attack_mod, advantage, disadvantage)
	result.attack_roll = d20_result

	var target_ac := calculate_ac(target)

	# A natural 20 always hits; a natural 1 always misses.
	if d20_result.is_critical:
		result.hit = true
		result.critical = true
	elif d20_result.is_fumble:
		result.hit = false
	else:
		result.hit = d20_result.total >= target_ac

	# Roll damage if the attack hits.
	if result.hit:
		var damage_notation: String = weapon_or_spell.get("damage_dice") if weapon_or_spell.get("damage_dice") else "1d4"
		var damage_result = DiceRoller.roll(damage_notation)

		if result.critical:
			# Critical hit: roll the damage dice a second time.
			var crit_extra = DiceRoller.roll(damage_notation)
			damage_result.total += crit_extra.total
			damage_result.rolls.append_array(crit_extra.rolls)

		# Add flat damage modifier from the weapon / spell, if any.
		var flat_damage_mod: int = weapon_or_spell.get("damage_modifier") if weapon_or_spell.get("damage_modifier") else 0
		damage_result.total += flat_damage_mod

		result.damage_total = damage_result.total
		result.damage_rolls = Array(damage_result.rolls)

	return result


# ===========================================================================
# Saving throws
# ===========================================================================

## Resolve a saving throw against a given DC.
func resolve_saving_throw(
	character: CharacterData,
	dc: int,
	ability: StringName,
	advantage: bool = false,
	disadvantage: bool = false,
) -> SaveResult:
	var result := SaveResult.new()
	result.dc = dc

	var ability_mod: int = character.get_modifier(ability)
	var total_mod: int = ability_mod

	# Add proficiency bonus if the character is proficient in this save.
	# Check via the character's class saving throw proficiencies.
	if character.character_class != null and ability in character.character_class.saving_throw_proficiencies:
		total_mod += get_proficiency_bonus(character.level)

	var d20_result = DiceRoller.saving_throw(total_mod, advantage, disadvantage)
	result.roll_result = d20_result
	result.success = d20_result.total >= dc

	return result


# ===========================================================================
# Skill checks
# ===========================================================================

## Return the total skill modifier for a character in a given skill.
func get_skill_modifier(character: CharacterData, skill: StringName) -> int:
	return character.get_skill_modifier(skill)


## Passive score = 10 + skill modifier (used for passive Perception, etc.).
func get_passive_score(character: CharacterData, skill: StringName) -> int:
	return 10 + get_skill_modifier(character, skill)


# ===========================================================================
# Initiative
# ===========================================================================

## Calculate the initiative modifier for a character (DEX mod + any bonuses).
func calculate_initiative(character: CharacterData) -> int:
	var dex_mod: int = character.get_modifier(&"dexterity")
	return dex_mod + character.initiative_bonus


# ===========================================================================
# Encumbrance & carry capacity
# ===========================================================================

## Maximum carrying capacity in pounds: STR score * 15.
func get_carry_capacity(character: CharacterData) -> float:
	var str_score: int = character.ability_scores.get_score(&"strength")
	return float(str_score) * 15.0


## Whether the character is encumbered (variant rule): weight > STR * 5.
func is_encumbered(character: CharacterData, total_weight: float) -> bool:
	var str_score: int = character.ability_scores.get_score(&"strength")
	return total_weight > float(str_score) * 5.0


## Whether the character is heavily encumbered: weight > STR * 10.
func is_heavily_encumbered(character: CharacterData, total_weight: float) -> bool:
	var str_score: int = character.ability_scores.get_score(&"strength")
	return total_weight > float(str_score) * 10.0


# ===========================================================================
# Private helpers
# ===========================================================================

## Determine the spellcasting ability for a character based on their class.
func _get_casting_ability(character: CharacterData) -> StringName:
	# Use the spellcasting_ability defined on the ClassData resource.
	if character.character_class != null and character.character_class.spellcasting_ability != &"":
		return character.character_class.spellcasting_ability
	return &"intelligence"

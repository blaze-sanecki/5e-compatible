class_name RestSystem
extends RefCounted

## Centralised rest logic for short and long rests (SRD 5.2.1).
##
## Static methods operate on CharacterData directly so neither
## CharacterData nor the UI need to own rest rules.


## Short rest: spend one hit die to heal (hit die + CON modifier, min 1).
## Returns the amount healed (0 if no hit dice remaining or already full).
static func short_rest(character: CharacterData) -> int:
	if character.hit_dice_remaining <= 0:
		return 0
	if character.current_hp >= character.max_hp:
		return 0

	character.hit_dice_remaining -= 1

	var hit_die: int = 8
	if character.character_class != null:
		hit_die = character.character_class.hit_die

	var con_mod: int = character.get_modifier(&"constitution")
	var roll_result = DiceRoller.roll("1d%d" % hit_die)
	var heal_amount: int = maxi(roll_result.total + con_mod, 1)
	var old_hp: int = character.current_hp
	character.current_hp = mini(character.current_hp + heal_amount, character.max_hp)
	var actual_heal: int = character.current_hp - old_hp
	if actual_heal > 0:
		EventBus.character_healed.emit(character, actual_heal)
	return actual_heal


## Long rest: restore HP to max, recover half total hit dice (min 1),
## restore all spell slots, and clear death saves.
static func long_rest(character: CharacterData) -> int:
	var old_hp: int = character.current_hp
	character.current_hp = character.max_hp

	# Recover half of total hit dice (minimum 1).
	var total_hit_dice: int = character.level
	@warning_ignore("integer_division")
	var recovered: int = maxi(total_hit_dice / 2, 1)
	character.hit_dice_remaining = mini(character.hit_dice_remaining + recovered, total_hit_dice)

	# Restore spell slots.
	for i in character.spell_slots.size():
		character.spell_slots[i] = character.max_spell_slots[i]

	# Clear death saves.
	character.death_save_successes = 0
	character.death_save_failures = 0

	return character.current_hp - old_hp

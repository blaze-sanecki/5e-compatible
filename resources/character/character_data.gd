class_name CharacterData
extends Resource

## The main character sheet resource. Uses composition to bring together
## ability scores, class, subclass, species, background, feats, inventory,
## spells, and all other character state.

## Maps each 5e skill to its governing ability score.
const SKILL_ABILITY_MAP: Dictionary = {
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

# --- Identity ---

## The character's name.
@export var character_name: String
## The player's name.
@export var player_name: String
## The character's alignment (e.g., "Lawful Good").
@export var alignment: String
## Freeform notes for the player.
@export_multiline var notes: String

# --- Core Progression ---

## Current character level (1-20).
@export var level: int = 1
## Total accumulated experience points.
@export var experience_points: int = 0

# --- Sub-Resources ---

## The six ability scores.
@export var ability_scores: AbilityScores
## The character's class.
@export var character_class: ClassData
## The character's subclass (chosen at the class's subclass_level).
@export var subclass: SubclassData
## The character's species (race).
@export var species: SpeciesData
## The character's background.
@export var background: BackgroundData

# --- Hit Points & Combat ---

## Maximum hit points.
@export var max_hp: int = 10
## Current hit points.
@export var current_hp: int = 10
## Temporary hit points.
@export var temp_hp: int = 0
## Armor class.
@export var armor_class: int = 10
## Initiative bonus.
@export var initiative_bonus: int = 0
## Movement speed in feet.
@export var speed: int = 30

# --- Hit Dice & Death Saves ---

## Number of hit dice remaining (resets on long rest).
@export var hit_dice_remaining: int = 1
## Death saving throw successes (0-3).
@export var death_save_successes: int = 0
## Death saving throw failures (0-3).
@export var death_save_failures: int = 0

# --- Proficiencies ---

## Skills the character is proficient in.
@export var skill_proficiencies: Array[StringName]
## Skills the character has expertise in (double proficiency bonus).
@export var expertise: Array[StringName]

# --- Feats ---

## Feats the character has acquired.
@export var feats: Array[FeatData]

# --- Inventory & Equipment ---

## All items in the character's inventory (ItemData references).
@export var inventory: Array[Resource]
## Currently equipped armor.
@export var equipped_armor: Resource
## Currently equipped shield.
@export var equipped_shield: Resource
## Currently equipped weapons.
@export var equipped_weapons: Array[Resource]
## Gold pieces.
@export var gold: int = 0

# --- Spellcasting ---

## Current remaining spell slots per spell level (index 0 = 1st level, index 8 = 9th level).
@export var spell_slots: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
## Maximum spell slots per spell level (index 0 = 1st level, index 8 = 9th level).
@export var max_spell_slots: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
## Spells currently prepared for casting (SpellData references).
@export var prepared_spells: Array[Resource]
## Spells the character knows (SpellData references).
@export var known_spells: Array[Resource]
## Cantrips the character knows (SpellData references).
@export var known_cantrips: Array[Resource]
## The spell the character is currently concentrating on, if any.
@export var concentration_spell: Resource

# --- Conditions & Languages ---

## Currently active conditions (e.g., "poisoned", "frightened").
@export var conditions: Array[StringName]
## Languages the character can speak, read, and write.
@export var languages: Array[StringName]


# ---------------------------------------------------------------------------
#  Methods
# ---------------------------------------------------------------------------

## Returns the proficiency bonus for the current level.
## Standard 5e formula: floor((level - 1) / 4) + 2.
func get_proficiency_bonus() -> int:
	@warning_ignore("integer_division")
	return int(floor(float(level - 1) / 4.0)) + 2


## Returns the ability modifier for the given ability.
## Delegates to the AbilityScores sub-resource.
func get_modifier(ability: StringName) -> int:
	if ability_scores == null:
		push_error("CharacterData: ability_scores is null")
		return 0
	return ability_scores.get_modifier(ability)


## Returns true if the character is proficient in the given skill.
func is_proficient_in_skill(skill: StringName) -> bool:
	return skill in skill_proficiencies


## Returns true if the character has expertise in the given skill.
func has_expertise_in(skill: StringName) -> bool:
	return skill in expertise


## Returns the total skill modifier for the given skill.
## This is the ability modifier plus proficiency bonus (if proficient),
## plus an additional proficiency bonus if the character has expertise.
func get_skill_modifier(skill: StringName) -> int:
	var ability: StringName = SKILL_ABILITY_MAP.get(skill, &"")
	if ability == &"":
		push_error("CharacterData: Unknown skill '%s'" % skill)
		return 0

	var mod := get_modifier(ability)
	if is_proficient_in_skill(skill):
		mod += get_proficiency_bonus()
	if has_expertise_in(skill):
		mod += get_proficiency_bonus()
	return mod


## Short rest: spend one hit die to heal (hit die + CON modifier, min 1).
## Returns the amount healed (0 if no hit dice remaining).
func on_short_rest() -> int:
	if hit_dice_remaining <= 0:
		return 0
	if current_hp >= max_hp:
		return 0

	hit_dice_remaining -= 1

	var hit_die: int = 8  # Default d8.
	if character_class != null and character_class.get("hit_die") != null:
		hit_die = character_class.hit_die

	var con_mod: int = get_modifier(&"constitution")
	var roll_result = DiceRoller.roll("1d%d" % hit_die)
	var heal_amount: int = maxi(roll_result.total + con_mod, 1)
	var old_hp: int = current_hp
	current_hp = mini(current_hp + heal_amount, max_hp)
	var actual_heal: int = current_hp - old_hp
	if actual_heal > 0:
		EventBus.character_healed.emit(self, actual_heal)
	return actual_heal


## Long rest: restore HP to max, recover half total hit dice (min 1),
## and restore all spell slots.
func on_long_rest() -> void:
	current_hp = max_hp

	# Recover half of total hit dice (minimum 1).
	var total_hit_dice: int = level
	@warning_ignore("integer_division")
	var recovered: int = maxi(total_hit_dice / 2, 1)
	hit_dice_remaining = mini(hit_dice_remaining + recovered, total_hit_dice)

	# Restore spell slots.
	for i in spell_slots.size():
		spell_slots[i] = max_spell_slots[i]

	# Clear death saves.
	death_save_successes = 0
	death_save_failures = 0

class_name ClassData
extends Resource

## Resource defining a character class (e.g., Fighter, Wizard, Rogue).
## Contains all static data about the class including proficiencies,
## features, and spellcasting information.

## Unique identifier for this class (e.g., "fighter", "wizard").
@export var id: StringName
## Human-readable name for display (e.g., "Fighter").
@export var display_name: String
## Full text description of the class.
@export_multiline var description: String

## The hit die size for this class (e.g., 10 for d10, 6 for d6).
@export var hit_die: int = 8
## The primary ability score used by this class.
@export var primary_ability: StringName

## Saving throw proficiencies granted by this class.
@export var saving_throw_proficiencies: Array[StringName]
## Armor types the class is proficient with.
@export var armor_proficiencies: Array[StringName]
## Weapon types the class is proficient with.
@export var weapon_proficiencies: Array[StringName]
## Tool types the class is proficient with.
@export var tool_proficiencies: Array[StringName]

## The list of skills this class can choose proficiency in.
@export var skill_choices: Array[StringName]
## How many skills the player may choose from skill_choices.
@export var num_skill_choices: int = 2

## Text descriptions of starting equipment options.
@export var starting_equipment_options: Array[String]

## The ability used for spellcasting. Empty if the class is not a caster.
@export var spellcasting_ability: StringName
## Whether this class has spellcasting ability.
@export var is_spellcaster: bool = false

## The character level at which a subclass is chosen.
@export var subclass_level: int = 3

## Class features gained at each level.
## Each entry is a Dictionary with keys: "level" (int), "name" (String), "description" (String).
@export var class_features: Array[Dictionary]


## Returns all class features gained at the specified level.
func get_features_at_level(level: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for feature in class_features:
		if feature.get("level", 0) == level:
			results.append(feature)
	return results

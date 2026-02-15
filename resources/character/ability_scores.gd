class_name AbilityScores
extends Resource

## Resource holding the six core ability scores and computed modifiers.

## The six ability score names used throughout the system.
const ABILITIES: Array[StringName] = [
	&"strength",
	&"dexterity",
	&"constitution",
	&"intelligence",
	&"wisdom",
	&"charisma",
]

## Strength score.
@export var strength: int = 10
## Dexterity score.
@export var dexterity: int = 10
## Constitution score.
@export var constitution: int = 10
## Intelligence score.
@export var intelligence: int = 10
## Wisdom score.
@export var wisdom: int = 10
## Charisma score.
@export var charisma: int = 10


## Returns the ability modifier for the given ability.
## The modifier is calculated as floor((score - 10) / 2).
func get_modifier(ability: StringName) -> int:
	var score := get_score(ability)
	@warning_ignore("integer_division")
	return int(floor(float(score - 10) / 2.0))


## Returns the raw ability score for the given ability by name.
func get_score(ability: StringName) -> int:
	match ability:
		&"strength":
			return strength
		&"dexterity":
			return dexterity
		&"constitution":
			return constitution
		&"intelligence":
			return intelligence
		&"wisdom":
			return wisdom
		&"charisma":
			return charisma
		_:
			push_error("AbilityScores: Unknown ability '%s'" % ability)
			return 10


## Sets the raw ability score for the given ability by name.
func set_score(ability: StringName, value: int) -> void:
	match ability:
		&"strength":
			strength = value
		&"dexterity":
			dexterity = value
		&"constitution":
			constitution = value
		&"intelligence":
			intelligence = value
		&"wisdom":
			wisdom = value
		&"charisma":
			charisma = value
		_:
			push_error("AbilityScores: Unknown ability '%s'" % ability)

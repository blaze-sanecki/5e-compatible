class_name DamageRoll
extends Resource

## Represents a damage roll expression (e.g., 2d6+3 fire damage).
## Used by weapons, spells, monster attacks, and any other damage source.

## All standard 5e damage types.
const DAMAGE_TYPES: Array[StringName] = [
	&"acid",
	&"bludgeoning",
	&"cold",
	&"fire",
	&"force",
	&"lightning",
	&"necrotic",
	&"piercing",
	&"poison",
	&"psychic",
	&"radiant",
	&"slashing",
	&"thunder",
]

## Number of dice to roll.
@export var dice_count: int = 1

## Size of each die (e.g., 6 for d6, 8 for d8).
@export var dice_size: int = 6

## Flat bonus added to the roll result.
@export var bonus: int = 0

## The type of damage dealt (e.g., "bludgeoning", "fire").
@export var damage_type: StringName = &"bludgeoning"


## Returns dice notation string such as "2d6+3" or "1d8" or "1d4-1".
func to_notation() -> String:
	var notation: String = "%dd%d" % [dice_count, dice_size]
	if bonus > 0:
		notation += "+%d" % bonus
	elif bonus < 0:
		notation += "%d" % bonus
	return notation

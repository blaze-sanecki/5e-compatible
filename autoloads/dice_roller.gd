## Full dice-rolling system following 5e conventions.
##
## Registered as an autoload singleton. Call DiceRoller.roll("2d6+3") or use
## the specialised helpers for d20-based checks from anywhere in the project.
extends Node

# ===========================================================================
# Inner classes
# ===========================================================================

## Stores the outcome of a generic dice roll.
class DiceResult:
	var total: int = 0
	var rolls: Array[int] = []
	var modifier: int = 0
	var notation: String = ""

	func _to_string() -> String:
		return "%s = %d (rolls: %s, modifier: %+d)" % [notation, total, str(rolls), modifier]


## Extends DiceResult with d20-specific metadata (crits, advantage, etc.).
class D20Result extends DiceResult:
	var natural_roll: int = 0
	var is_critical: bool = false
	var is_fumble: bool = false
	var had_advantage: bool = false
	var had_disadvantage: bool = false

	func _to_string() -> String:
		var extras: PackedStringArray = []
		if is_critical:
			extras.append("CRITICAL")
		if is_fumble:
			extras.append("FUMBLE")
		if had_advantage:
			extras.append("advantage")
		if had_disadvantage:
			extras.append("disadvantage")
		var extra_str := " [%s]" % ", ".join(extras) if extras.size() > 0 else ""
		return "d20 = %d (natural %d, modifier %+d)%s" % [total, natural_roll, modifier, extra_str]


# ===========================================================================
# Regex compiled once and reused
# ===========================================================================
var _dice_regex: RegEx


func _ready() -> void:
	_dice_regex = RegEx.new()
	# Matches patterns like "2d6+3", "1d20", "4d6", "1d8-1"
	_dice_regex.compile("^(\\d+)[dD](\\d+)([+-]\\d+)?$")


# ===========================================================================
# Public API
# ===========================================================================

## Parse standard dice notation (e.g. "2d6+3") and return the result.
func roll(notation: String) -> DiceResult:
	var clean := notation.strip_edges().replace(" ", "")
	var regex_match := _dice_regex.search(clean)
	if regex_match == null:
		push_warning("DiceRoller: Invalid notation '%s'. Returning zero result." % notation)
		var result := DiceResult.new()
		result.notation = notation
		return result

	var count := regex_match.get_string(1).to_int()
	var sides := regex_match.get_string(2).to_int()
	var mod := 0
	if regex_match.get_string(3) != "":
		mod = regex_match.get_string(3).to_int()

	var result := roll_dice(count, sides, mod)
	result.notation = clean
	return result


## Roll [code]count[/code] dice with [code]sides[/code] faces, adding an
## optional flat modifier.
func roll_dice(count: int, sides: int, modifier: int = 0) -> DiceResult:
	var result := DiceResult.new()
	result.modifier = modifier
	result.notation = "%dd%d%s" % [count, sides, ("%+d" % modifier) if modifier != 0 else ""]

	var sum := 0
	for i in count:
		var value := randi_range(1, sides)
		result.rolls.append(value)
		sum += value

	result.total = sum + modifier
	return result


## Roll a d20 with optional advantage / disadvantage.
##
## If both advantage and disadvantage are true they cancel out (straight roll).
func roll_d20(modifier: int = 0, advantage: bool = false, disadvantage: bool = false) -> D20Result:
	var result := D20Result.new()
	result.modifier = modifier

	# Advantage + disadvantage cancel out.
	var use_advantage := advantage and not disadvantage
	var use_disadvantage := disadvantage and not advantage
	result.had_advantage = use_advantage
	result.had_disadvantage = use_disadvantage

	var roll_1 := randi_range(1, 20)

	if use_advantage or use_disadvantage:
		var roll_2 := randi_range(1, 20)
		if use_advantage:
			result.natural_roll = maxi(roll_1, roll_2)
			result.rolls = [roll_1, roll_2] as Array[int]
		else:
			result.natural_roll = mini(roll_1, roll_2)
			result.rolls = [roll_1, roll_2] as Array[int]
	else:
		result.natural_roll = roll_1
		result.rolls = [roll_1] as Array[int]

	result.is_critical = result.natural_roll == 20
	result.is_fumble = result.natural_roll == 1
	result.total = result.natural_roll + modifier
	result.notation = "1d20%s" % (("%+d" % modifier) if modifier != 0 else "")

	return result


## Ability check: d20 + modifier with optional advantage / disadvantage.
func ability_check(modifier: int, advantage: bool = false, disadvantage: bool = false) -> D20Result:
	return roll_d20(modifier, advantage, disadvantage)


## Saving throw: d20 + modifier with optional advantage / disadvantage.
func saving_throw(modifier: int, advantage: bool = false, disadvantage: bool = false) -> D20Result:
	return roll_d20(modifier, advantage, disadvantage)


## Attack roll: d20 + modifier with optional advantage / disadvantage.
func attack_roll(modifier: int, advantage: bool = false, disadvantage: bool = false) -> D20Result:
	return roll_d20(modifier, advantage, disadvantage)


## Roll a single ability score using the 4d6-drop-lowest method.
func roll_stat() -> int:
	var dice: Array[int] = []
	for i in 4:
		dice.append(randi_range(1, 6))
	dice.sort()
	# Drop the lowest die (index 0 after sort) and sum the top three.
	return dice[1] + dice[2] + dice[3]


## Roll hit points for a given level.
##
## Level 1 always grants max hit die + CON modifier.
## Subsequent levels roll the hit die and add the CON modifier (minimum 1 HP
## gained per level).
func roll_hp(hit_die: int, con_modifier: int, level: int) -> int:
	if level <= 0:
		return 0

	# Level 1: max die value + CON modifier (minimum 1).
	var hp := maxi(hit_die + con_modifier, 1)

	# Levels 2+
	for i in range(2, level + 1):
		var roll_value := randi_range(1, hit_die)
		hp += maxi(roll_value + con_modifier, 1)

	return hp

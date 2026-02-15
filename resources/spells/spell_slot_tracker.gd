class_name SpellSlotTracker
extends Resource

## Tracks available and maximum spell slots for spell levels 1 through 9.
## Index 0 corresponds to 1st-level slots, index 8 to 9th-level slots.

## Maximum spell slots for each level (index 0 = 1st level, index 8 = 9th level).
@export var max_slots: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]

## Currently available spell slots for each level.
@export var current_slots: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]


## Returns true if the caster has at least one slot available at the given spell level.
## spell_level is 1-9 (not 0-indexed).
func can_cast(spell_level: int) -> bool:
	if spell_level < 1 or spell_level > 9:
		return false
	return current_slots[spell_level - 1] > 0


## Expends one spell slot at the given level. Returns true on success,
## false if no slot is available at that level.
## spell_level is 1-9.
func use_slot(spell_level: int) -> bool:
	if not can_cast(spell_level):
		return false
	current_slots[spell_level - 1] -= 1
	return true


## Restores all spell slots to their maximum values (e.g., after a long rest).
func restore_all_slots() -> void:
	for i in range(9):
		current_slots[i] = max_slots[i]


## Restores one spell slot at the given level, up to the maximum.
## spell_level is 1-9.
func restore_slot(spell_level: int) -> void:
	if spell_level < 1 or spell_level > 9:
		return
	var idx: int = spell_level - 1
	current_slots[idx] = mini(current_slots[idx] + 1, max_slots[idx])


## Returns the number of available spell slots at the given level.
## spell_level is 1-9.
func get_available(spell_level: int) -> int:
	if spell_level < 1 or spell_level > 9:
		return 0
	return current_slots[spell_level - 1]

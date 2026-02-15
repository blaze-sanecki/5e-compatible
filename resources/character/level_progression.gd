class_name LevelProgression
extends Resource

## Resource defining level-up progression data for a specific class.
## Contains proficiency bonuses, features, and spell slot information
## for each level from 1 to 20.

## The class id this progression belongs to (e.g., "fighter", "wizard").
@export var class_id: StringName

## Progression data for each level (1-20).
## Each entry is a Dictionary with keys:
##   "level" (int) - The character level.
##   "proficiency_bonus" (int) - Proficiency bonus at this level.
##   "features" (Array[Dictionary]) - Features gained at this level,
##       each with "name" (String) and "description" (String).
##   "spell_slots" (Array[int]) - Spell slots per level 1-9 (casters only).
##   Additional class-specific keys as needed (e.g., "rage_count", "sneak_attack_dice").
@export var levels: Array[Dictionary]


## Returns the proficiency bonus for the given character level.
## Falls back to the standard formula if no entry is found.
func get_proficiency_bonus(level: int) -> int:
	for entry in levels:
		if entry.get("level", 0) == level:
			return entry.get("proficiency_bonus", _default_proficiency_bonus(level))
	return _default_proficiency_bonus(level)


## Returns all features gained at the given level.
func get_features(level: int) -> Array[Dictionary]:
	for entry in levels:
		if entry.get("level", 0) == level:
			var raw_features = entry.get("features", [])
			var results: Array[Dictionary] = []
			for feature in raw_features:
				results.append(feature)
			return results
	return [] as Array[Dictionary]


## Returns the spell slots available at the given level as an array of 9 ints
## representing slots for spell levels 1 through 9.
## Returns an array of zeros if no spell slot data exists for this level.
func get_spell_slots(level: int) -> Array[int]:
	for entry in levels:
		if entry.get("level", 0) == level:
			var raw_slots = entry.get("spell_slots", [])
			var slots: Array[int] = []
			for slot in raw_slots:
				slots.append(int(slot))
			# Pad to 9 entries if needed.
			while slots.size() < 9:
				slots.append(0)
			return slots
	return [0, 0, 0, 0, 0, 0, 0, 0, 0] as Array[int]


## Standard 5e proficiency bonus formula as a fallback.
func _default_proficiency_bonus(level: int) -> int:
	@warning_ignore("integer_division")
	return int(floor(float(level - 1) / 4.0)) + 2

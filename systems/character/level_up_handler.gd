class_name LevelUpHandler
extends RefCounted

## Static utility methods for character level advancement.
## Handles XP tracking, HP increases, feature grants, and ASI levels.


## Returns true if the character has enough XP to level up.
static func can_level_up(character: CharacterData) -> bool:
	if character.level >= 20:
		return false
	var next_level: int = character.level + 1
	return character.experience_points >= GameBalance.XP_THRESHOLDS[next_level - 1]


## Add experience to a character and emit signals.
static func add_experience(character: CharacterData, amount: int) -> void:
	character.experience_points += amount
	EventBus.experience_gained.emit(character, amount)


## Returns the XP needed to reach the next level.
static func xp_to_next_level(character: CharacterData) -> int:
	if character.level >= 20:
		return 0
	return GameBalance.XP_THRESHOLDS[character.level] - character.experience_points


## Returns true if the given level grants an ASI / feat choice.
static func level_grants_asi(level: int) -> bool:
	return level in GameBalance.ASI_LEVELS


## Returns the HP options for leveling up: [average, hit_die_size].
## Average = ceil(hit_die / 2) + 1 (the "take average" option in 5e).
static func get_hp_options(character: CharacterData) -> Dictionary:
	if character.character_class == null:
		return {"average": 5, "hit_die": 8}
	var die: int = character.character_class.hit_die
	@warning_ignore("integer_division")
	var avg: int = (die / 2) + 1  # Standard 5e average.
	return {"average": avg, "hit_die": die}


## Apply a level up to the character.
##
## [param hp_roll] — The HP gained this level (either the average or a rolled value).
## [param asi_choices] — Optional dictionary of ability increases, e.g. {"strength": 2}
##                       or {"dexterity": 1, "constitution": 1}. Only used at ASI levels.
static func apply_level_up(
	character: CharacterData,
	hp_roll: int,
	asi_choices: Dictionary = {},
) -> void:
	if character.level >= 20:
		push_error("LevelUpHandler: Character is already level 20.")
		return

	character.level += 1
	var new_level: int = character.level

	# HP increase (minimum 1).
	var con_mod: int = character.ability_scores.get_modifier(&"constitution")
	var hp_gain: int = maxi(hp_roll + con_mod, 1)
	character.max_hp += hp_gain
	character.current_hp += hp_gain
	character.hit_dice_remaining += 1

	# Apply ASI if this is an ASI level.
	if level_grants_asi(new_level) and asi_choices.size() > 0:
		for ability_key in asi_choices:
			var increase: int = int(asi_choices[ability_key])
			var current: int = character.ability_scores.get_score(StringName(ability_key))
			character.ability_scores.set_score(StringName(ability_key), mini(current + increase, 20))
		# Recalculate HP if CON changed.
		var new_con_mod: int = character.ability_scores.get_modifier(&"constitution")
		if new_con_mod != con_mod:
			# Retroactively adjust HP for the CON change across all levels.
			var diff: int = new_con_mod - con_mod
			character.max_hp += diff * new_level
			character.current_hp += diff * new_level
			if character.max_hp < 1:
				character.max_hp = 1
			if character.current_hp < 1:
				character.current_hp = 1

	# Update spell slots for casters.
	if character.character_class != null and character.character_class.is_spellcaster:
		var progression: LevelProgression = DataRegistry.get_level_progression(character.character_class.id)
		if progression != null:
			var new_slots: Array[int] = progression.get_spell_slots(new_level)
			# Grant new slot maximums.
			character.max_spell_slots = new_slots.duplicate()
			# Restore to new maximums (level-up is a celebration).
			character.spell_slots = new_slots.duplicate()

	# Recalculate AC (in case gear or DEX changed).
	character.armor_class = RulesEngine.calculate_ac(character)

	# Emit signal.
	EventBus.level_up.emit(character, new_level)


## Returns the features gained at a specific level for the character's class.
static func get_features_at_level(character: CharacterData, level: int) -> Array[ClassFeature]:
	if character.character_class == null:
		return [] as Array[ClassFeature]

	# Try level progression first.
	var progression: LevelProgression = DataRegistry.get_level_progression(character.character_class.id)
	if progression != null:
		return progression.get_features(level)

	# Fallback to class data.
	return character.character_class.get_features_at_level(level)

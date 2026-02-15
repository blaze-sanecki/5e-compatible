class_name CombatRewards
extends RefCounted

## Calculates and distributes XP rewards after combat.


## Calculate and distribute XP from a combat encounter to the party.
## Returns a dictionary with total XP and per-character XP.
static func award_xp(combatants: Array[CombatantData],
		encounter: CombatEncounterData = null) -> Dictionary:
	if encounter != null and not encounter.grants_xp:
		return {"total_xp": 0, "per_character": 0, "level_ups": []}

	# Sum XP from all defeated monsters.
	var total_xp: int = 0
	for c in combatants:
		if c.is_monster() and c.is_dead:
			var monster: MonsterData = c.source as MonsterData
			if monster:
				total_xp += monster.xp_reward

	if total_xp <= 0:
		return {"total_xp": 0, "per_character": 0, "level_ups": []}

	# Divide among living party members.
	var living_players: Array[CombatantData] = []
	for c in combatants:
		if c.is_player() and not c.is_dead:
			living_players.append(c)

	var party_size: int = maxi(living_players.size(), 1)
	@warning_ignore("integer_division")
	var xp_each: int = total_xp / party_size

	var level_ups: Array[String] = []

	for player in living_players:
		if player.source.get("experience_points") != null:
			player.source.experience_points += xp_each
			EventBus.experience_gained.emit(player.source, xp_each)

			# Check for level up.
			var new_level: int = _check_level_up(player.source)
			if new_level > 0:
				level_ups.append(player.display_name)

	return {
		"total_xp": total_xp,
		"per_character": xp_each,
		"level_ups": level_ups,
	}


## Check if a character should level up based on their XP.
## Returns the new level or 0 if no level up.
static func _check_level_up(character: Resource) -> int:
	if character.get("experience_points") == null or character.get("level") == null:
		return 0

	var xp: int = character.experience_points
	var current_level: int = character.level
	var next_level: int = current_level + 1

	var threshold: int = _xp_threshold(next_level)
	if threshold > 0 and xp >= threshold:
		# Don't auto-level — just signal. The LevelUpHandler will handle it.
		EventBus.level_up.emit(character, next_level)
		return next_level

	return 0


## XP thresholds per level (5e SRD).
static func _xp_threshold(level: int) -> int:
	var thresholds: Array[int] = [
		0,      # Level 1 (always)
		300,    # Level 2
		900,    # Level 3
		2700,   # Level 4
		6500,   # Level 5
		14000,  # Level 6
		23000,  # Level 7
		34000,  # Level 8
		48000,  # Level 9
		64000,  # Level 10
		85000,  # Level 11
		100000, # Level 12
		120000, # Level 13
		140000, # Level 14
		165000, # Level 15
		195000, # Level 16
		225000, # Level 17
		265000, # Level 18
		305000, # Level 19
		355000, # Level 20
	]
	if level < 1 or level > 20:
		return 0
	return thresholds[level - 1]

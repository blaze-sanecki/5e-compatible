## Generates combat-related .tres data files: conditions, monsters, encounters.
## Run the combat_data_generator.tscn scene (F6) to populate data/.
extends Node


func _ready() -> void:
	print("=== Combat Data Generator ===")
	_generate_conditions()
	_generate_monsters()
	_generate_encounters()
	print("=== Combat data generation complete! ===")
	get_tree().quit()


static func _ce(t: StringName, on_field: StringName = &"", val: int = 0) -> ConditionEffect:
	var e := ConditionEffect.new()
	e.type = t
	e.on = on_field
	e.value = val
	return e


static func _mt(n: String, desc: String) -> MonsterTrait:
	var t := MonsterTrait.new()
	t.name = n
	t.description = desc
	return t


static func _ma(n: String, t: StringName, atk: int, rch: int, dmg: String, dt: StringName, desc: String = "") -> MonsterAction:
	var a := MonsterAction.new()
	a.name = n
	a.type = t
	a.attack_bonus = atk
	a.reach = rch
	a.damage = dmg
	a.damage_type = dt
	a.description = desc
	return a


static func _mse(mid: StringName, c: Vector2i, cnt: int = 1) -> MonsterSpawnEntry:
	var s := MonsterSpawnEntry.new()
	s.monster_id = mid
	s.cell = c
	s.count = cnt
	return s


func _save(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Failed to save: %s (error %d)" % [path, err])
	else:
		print("  Saved: %s" % path)


# ===========================================================================
# Conditions (SRD Appendix A)
# ===========================================================================

func _generate_conditions() -> void:
	print("Generating conditions...")

	_save_condition(&"blinded", "Blinded",
		"A blinded creature can't see and automatically fails any ability check that requires sight. Attack rolls against the creature have advantage, and the creature's attack rolls have disadvantage.",
		[
			_ce(&"auto_fail", &"ability_checks_requiring_sight"),
			_ce(&"advantage", &"attack_rolls_against"),
			_ce(&"disadvantage", &"attack_rolls"),
		], &"never")

	_save_condition(&"charmed", "Charmed",
		"A charmed creature can't attack the charmer or target the charmer with harmful abilities or magical effects. The charmer has advantage on any ability check to interact socially with the creature.",
		[
			_ce(&"cant_attack", &"charmer"),
			_ce(&"advantage", &"social_checks_by_charmer"),
		], &"save")

	_save_condition(&"deafened", "Deafened",
		"A deafened creature can't hear and automatically fails any ability check that requires hearing.",
		[
			_ce(&"auto_fail", &"ability_checks_requiring_hearing"),
		], &"never")

	_save_condition(&"frightened", "Frightened",
		"A frightened creature has disadvantage on ability checks and attack rolls while the source of its fear is within line of sight. The creature can't willingly move closer to the source of its fear.",
		[
			_ce(&"disadvantage", &"ability_checks"),
			_ce(&"disadvantage", &"attack_rolls"),
			_ce(&"cant_approach", &"fear_source"),
		], &"save")

	_save_condition(&"grappled", "Grappled",
		"A grappled creature's speed becomes 0, and it can't benefit from any bonus to its speed. The condition ends if the grappler is incapacitated or the creature is moved out of reach.",
		[
			_ce(&"speed", &"", 0),
		], &"custom")

	_save_condition(&"incapacitated", "Incapacitated",
		"An incapacitated creature can't take actions or reactions.",
		[
			_ce(&"cant_act", &"actions"),
			_ce(&"cant_act", &"reactions"),
		], &"never")

	_save_condition(&"invisible", "Invisible",
		"An invisible creature is impossible to see without the aid of magic or a special sense. The creature's attack rolls have advantage, and attack rolls against the creature have disadvantage.",
		[
			_ce(&"advantage", &"attack_rolls"),
			_ce(&"disadvantage", &"attack_rolls_against"),
			_ce(&"unseen", &"sight"),
		], &"custom")

	_save_condition(&"paralyzed", "Paralyzed",
		"A paralyzed creature is incapacitated and can't move or speak. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage. Any attack that hits is a critical hit if the attacker is within 5 feet.",
		[
			_ce(&"incapacitated", &"all"),
			_ce(&"speed", &"", 0),
			_ce(&"auto_fail", &"strength_saves"),
			_ce(&"auto_fail", &"dexterity_saves"),
			_ce(&"advantage", &"attack_rolls_against"),
			_ce(&"auto_crit", &"melee_attacks_against"),
		], &"save")

	_save_condition(&"petrified", "Petrified",
		"A petrified creature is transformed into a solid inanimate substance. It is incapacitated, can't move or speak, and is unaware of its surroundings. Attack rolls against it have advantage. It automatically fails Strength and Dexterity saves. It has resistance to all damage and is immune to poison and disease.",
		[
			_ce(&"incapacitated", &"all"),
			_ce(&"speed", &"", 0),
			_ce(&"auto_fail", &"strength_saves"),
			_ce(&"auto_fail", &"dexterity_saves"),
			_ce(&"advantage", &"attack_rolls_against"),
			_ce(&"resistance", &"all_damage"),
			_ce(&"immunity", &"poison"),
		], &"never")

	_save_condition(&"poisoned", "Poisoned",
		"A poisoned creature has disadvantage on attack rolls and ability checks.",
		[
			_ce(&"disadvantage", &"attack_rolls"),
			_ce(&"disadvantage", &"ability_checks"),
		], &"save")

	_save_condition(&"prone", "Prone",
		"A prone creature's only movement option is to crawl (half speed) unless it stands up. The creature has disadvantage on attack rolls. An attack roll against the creature has advantage if the attacker is within 5 feet; otherwise, the attack roll has disadvantage.",
		[
			_ce(&"disadvantage", &"attack_rolls"),
			_ce(&"advantage", &"melee_attacks_against"),
			_ce(&"disadvantage", &"ranged_attacks_against"),
			_ce(&"movement_cost", &"", 2),
		], &"custom")

	_save_condition(&"restrained", "Restrained",
		"A restrained creature's speed becomes 0. Attack rolls against the creature have advantage, and the creature's attack rolls have disadvantage. The creature has disadvantage on Dexterity saving throws.",
		[
			_ce(&"speed", &"", 0),
			_ce(&"advantage", &"attack_rolls_against"),
			_ce(&"disadvantage", &"attack_rolls"),
			_ce(&"disadvantage", &"dexterity_saves"),
		], &"save")

	_save_condition(&"stunned", "Stunned",
		"A stunned creature is incapacitated, can't move, and can speak only falteringly. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage.",
		[
			_ce(&"incapacitated", &"all"),
			_ce(&"speed", &"", 0),
			_ce(&"auto_fail", &"strength_saves"),
			_ce(&"auto_fail", &"dexterity_saves"),
			_ce(&"advantage", &"attack_rolls_against"),
		], &"save")

	_save_condition(&"unconscious", "Unconscious",
		"An unconscious creature is incapacitated, can't move or speak, and is unaware of its surroundings. The creature drops whatever it's holding and falls prone. Attack rolls against the creature have advantage. Any attack that hits is a critical hit if the attacker is within 5 feet. The creature automatically fails Strength and Dexterity saving throws.",
		[
			_ce(&"incapacitated", &"all"),
			_ce(&"speed", &"", 0),
			_ce(&"auto_fail", &"strength_saves"),
			_ce(&"auto_fail", &"dexterity_saves"),
			_ce(&"advantage", &"attack_rolls_against"),
			_ce(&"auto_crit", &"melee_attacks_against"),
			_ce(&"prone", &"self"),
		], &"save")


func _save_condition(id: StringName, display_name: String, description: String,
		effects: Array[ConditionEffect], ends_on: StringName, save_ability: StringName = &"", save_dc: int = 0) -> void:
	var c := ConditionData.new()
	c.id = id
	c.display_name = display_name
	c.description = description
	c.effects = effects
	c.ends_on = ends_on
	c.save_ability = save_ability
	c.save_dc = save_dc
	_save(c, "res://data/conditions/%s.tres" % id)


# ===========================================================================
# Monsters (SRD stat blocks)
# ===========================================================================

func _generate_monsters() -> void:
	print("Generating monsters...")

	# --- Goblin (CR 1/4) ---
	var goblin := MonsterData.new()
	goblin.id = &"goblin"
	goblin.display_name = "Goblin"
	goblin.description = "Small, black-hearted humanoids that lair in despoiled dungeons."
	goblin.size = &"small"
	goblin.creature_type = &"humanoid"
	goblin.alignment = "neutral evil"
	goblin.armor_class = 15
	goblin.ac_description = "leather armor, shield"
	goblin.hit_points = 7
	goblin.hit_dice = "2d6"
	goblin.speed = {"walk": 30}
	goblin.ability_scores = _make_abilities(8, 14, 10, 10, 8, 8)
	goblin.skills = {"stealth": 6}
	goblin.senses = {"darkvision": 60, "passive_perception": 9}
	goblin.languages = [&"common", &"goblin"]
	goblin.challenge_rating = 0.25
	goblin.xp_reward = 50
	goblin.proficiency_bonus = 2
	goblin.traits = [
		_mt("Nimble Escape", "The goblin can take the Disengage or Hide action as a bonus action on each of its turns."),
	]
	var goblin_shortbow := _ma("Shortbow", &"ranged_attack", 4, 5, "1d6+2", &"piercing",
		"Ranged Weapon Attack: +4 to hit, range 80/320 ft., one target. Hit: 5 (1d6 + 2) piercing damage.")
	goblin_shortbow.range_normal = 80
	goblin_shortbow.range_long = 320
	goblin.actions = [
		_ma("Scimitar", &"melee_attack", 4, 5, "1d6+2", &"slashing",
			"Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 5 (1d6 + 2) slashing damage."),
		goblin_shortbow,
	]
	_save(goblin, "res://data/monsters/goblin.tres")

	# --- Skeleton (CR 1/4) ---
	var skeleton := MonsterData.new()
	skeleton.id = &"skeleton"
	skeleton.display_name = "Skeleton"
	skeleton.description = "Animated bones held together by dark magic."
	skeleton.size = &"medium"
	skeleton.creature_type = &"undead"
	skeleton.alignment = "lawful evil"
	skeleton.armor_class = 13
	skeleton.ac_description = "armor scraps"
	skeleton.hit_points = 13
	skeleton.hit_dice = "2d8+4"
	skeleton.speed = {"walk": 30}
	skeleton.ability_scores = _make_abilities(10, 14, 15, 6, 8, 5)
	skeleton.damage_vulnerabilities = [&"bludgeoning"]
	skeleton.damage_immunities = [&"poison"]
	skeleton.condition_immunities = [&"exhaustion", &"poisoned"]
	skeleton.senses = {"darkvision": 60, "passive_perception": 9}
	skeleton.languages = []
	skeleton.challenge_rating = 0.25
	skeleton.xp_reward = 50
	skeleton.proficiency_bonus = 2
	var skeleton_shortbow := _ma("Shortbow", &"ranged_attack", 4, 5, "1d6+2", &"piercing",
		"Ranged Weapon Attack: +4 to hit, range 80/320 ft., one target. Hit: 5 (1d6 + 2) piercing damage.")
	skeleton_shortbow.range_normal = 80
	skeleton_shortbow.range_long = 320
	skeleton.actions = [
		_ma("Shortsword", &"melee_attack", 4, 5, "1d6+2", &"piercing",
			"Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 5 (1d6 + 2) piercing damage."),
		skeleton_shortbow,
	]
	_save(skeleton, "res://data/monsters/skeleton.tres")

	# --- Wolf (CR 1/4) ---
	var wolf := MonsterData.new()
	wolf.id = &"wolf"
	wolf.display_name = "Wolf"
	wolf.description = "A fierce pack predator."
	wolf.size = &"medium"
	wolf.creature_type = &"beast"
	wolf.alignment = "unaligned"
	wolf.armor_class = 13
	wolf.ac_description = "natural armor"
	wolf.hit_points = 11
	wolf.hit_dice = "2d8+2"
	wolf.speed = {"walk": 40}
	wolf.ability_scores = _make_abilities(12, 15, 12, 3, 12, 6)
	wolf.skills = {"perception": 3, "stealth": 4}
	wolf.senses = {"passive_perception": 13}
	wolf.challenge_rating = 0.25
	wolf.xp_reward = 50
	wolf.proficiency_bonus = 2
	wolf.traits = [
		_mt("Keen Hearing and Smell", "The wolf has advantage on Wisdom (Perception) checks that rely on hearing or smell."),
		_mt("Pack Tactics", "The wolf has advantage on an attack roll against a creature if at least one of the wolf's allies is within 5 feet of the creature and the ally isn't incapacitated."),
	]
	var wolf_bite := _ma("Bite", &"melee_attack", 4, 5, "2d4+2", &"piercing",
		"Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 7 (2d4 + 2) piercing damage. If the target is a creature, it must succeed on a DC 11 Strength saving throw or be knocked prone.")
	wolf_bite.save_dc = 11
	wolf_bite.save_ability = &"strength"
	wolf_bite.save_effect = "prone"
	wolf.actions = [wolf_bite]
	_save(wolf, "res://data/monsters/wolf.tres")

	# --- Zombie (CR 1/4) ---
	var zombie := MonsterData.new()
	zombie.id = &"zombie"
	zombie.display_name = "Zombie"
	zombie.description = "A shambling corpse animated by dark magic."
	zombie.size = &"medium"
	zombie.creature_type = &"undead"
	zombie.alignment = "neutral evil"
	zombie.armor_class = 8
	zombie.hit_points = 22
	zombie.hit_dice = "3d8+9"
	zombie.speed = {"walk": 20}
	zombie.ability_scores = _make_abilities(13, 6, 16, 3, 6, 5)
	zombie.saving_throws = {"wisdom": 0}
	zombie.damage_immunities = [&"poison"]
	zombie.condition_immunities = [&"poisoned"]
	zombie.senses = {"darkvision": 60, "passive_perception": 8}
	zombie.languages = []
	zombie.challenge_rating = 0.25
	zombie.xp_reward = 50
	zombie.proficiency_bonus = 2
	zombie.traits = [
		_mt("Undead Fortitude", "If damage reduces the zombie to 0 hit points, it must make a Constitution saving throw with a DC of 5 + the damage taken, unless the damage is radiant or from a critical hit. On a success, the zombie drops to 1 hit point instead."),
	]
	zombie.actions = [
		_ma("Slam", &"melee_attack", 3, 5, "1d6+1", &"bludgeoning",
			"Melee Weapon Attack: +3 to hit, reach 5 ft., one target. Hit: 4 (1d6 + 1) bludgeoning damage."),
	]
	_save(zombie, "res://data/monsters/zombie.tres")

	# --- Orc (CR 1/2) ---
	var orc := MonsterData.new()
	orc.id = &"orc"
	orc.display_name = "Orc"
	orc.description = "A savage humanoid driven by fury and bloodlust."
	orc.size = &"medium"
	orc.creature_type = &"humanoid"
	orc.alignment = "chaotic evil"
	orc.armor_class = 13
	orc.ac_description = "hide armor"
	orc.hit_points = 15
	orc.hit_dice = "2d8+6"
	orc.speed = {"walk": 30}
	orc.ability_scores = _make_abilities(16, 12, 16, 7, 11, 10)
	orc.skills = {"intimidation": 2}
	orc.senses = {"darkvision": 60, "passive_perception": 10}
	orc.languages = [&"common", &"orc"]
	orc.challenge_rating = 0.5
	orc.xp_reward = 100
	orc.proficiency_bonus = 2
	orc.traits = [
		_mt("Aggressive", "As a bonus action, the orc can move up to its speed toward a hostile creature that it can see."),
	]
	var orc_javelin := _ma("Javelin", &"ranged_attack", 5, 5, "1d6+3", &"piercing",
		"Ranged Weapon Attack: +5 to hit, range 30/120 ft., one target. Hit: 6 (1d6 + 3) piercing damage.")
	orc_javelin.range_normal = 30
	orc_javelin.range_long = 120
	orc.actions = [
		_ma("Greataxe", &"melee_attack", 5, 5, "1d12+3", &"slashing",
			"Melee Weapon Attack: +5 to hit, reach 5 ft., one target. Hit: 9 (1d12 + 3) slashing damage."),
		orc_javelin,
	]
	_save(orc, "res://data/monsters/orc.tres")

	# --- Ogre (CR 2) ---
	var ogre := MonsterData.new()
	ogre.id = &"ogre"
	ogre.display_name = "Ogre"
	ogre.description = "A hulking giant that delights in brutality, smashing and devouring anything in its path."
	ogre.size = &"large"
	ogre.creature_type = &"giant"
	ogre.alignment = "chaotic evil"
	ogre.armor_class = 11
	ogre.ac_description = "hide armor"
	ogre.hit_points = 59
	ogre.hit_dice = "7d10+21"
	ogre.speed = {"walk": 40}
	ogre.ability_scores = _make_abilities(19, 8, 16, 5, 7, 7)
	ogre.senses = {"darkvision": 60, "passive_perception": 8}
	ogre.languages = [&"common", &"giant"]
	ogre.challenge_rating = 2.0
	ogre.xp_reward = 450
	ogre.proficiency_bonus = 2
	var ogre_javelin := _ma("Javelin", &"ranged_attack", 6, 5, "2d6+4", &"piercing",
		"Ranged Weapon Attack: +6 to hit, range 30/120 ft., one target. Hit: 11 (2d6 + 4) piercing damage.")
	ogre_javelin.range_normal = 30
	ogre_javelin.range_long = 120
	ogre.actions = [
		_ma("Greatclub", &"melee_attack", 6, 5, "2d8+4", &"bludgeoning",
			"Melee Weapon Attack: +6 to hit, reach 5 ft., one target. Hit: 13 (2d8 + 4) bludgeoning damage."),
		ogre_javelin,
	]
	_save(ogre, "res://data/monsters/ogre.tres")


func _make_abilities(str_val: int, dex: int, con: int, int_val: int, wis: int, cha: int) -> AbilityScores:
	var a := AbilityScores.new()
	a.strength = str_val
	a.dexterity = dex
	a.constitution = con
	a.intelligence = int_val
	a.wisdom = wis
	a.charisma = cha
	return a


# ===========================================================================
# Encounters
# ===========================================================================

func _generate_encounters() -> void:
	print("Generating encounters...")

	var enc := CombatEncounterData.new()
	enc.id = &"test_goblin_ambush"
	enc.display_name = "Goblin Ambush"
	enc.monster_spawns = [
		_mse(&"goblin", Vector2i(12, 3)),
		_mse(&"goblin", Vector2i(13, 5)),
		_mse(&"goblin", Vector2i(11, 5)),
	]
	enc.difficulty = &"easy"
	enc.grants_xp = true
	_save(enc, "res://data/encounters/test_goblin_ambush.tres")

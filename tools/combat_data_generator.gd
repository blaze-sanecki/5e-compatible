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
			{"type": "auto_fail", "on": "ability_checks_requiring_sight"},
			{"type": "advantage", "on": "attack_rolls_against"},
			{"type": "disadvantage", "on": "attack_rolls"},
		], &"never")

	_save_condition(&"charmed", "Charmed",
		"A charmed creature can't attack the charmer or target the charmer with harmful abilities or magical effects. The charmer has advantage on any ability check to interact socially with the creature.",
		[
			{"type": "cant_attack", "on": "charmer"},
			{"type": "advantage", "on": "social_checks_by_charmer"},
		], &"save")

	_save_condition(&"deafened", "Deafened",
		"A deafened creature can't hear and automatically fails any ability check that requires hearing.",
		[
			{"type": "auto_fail", "on": "ability_checks_requiring_hearing"},
		], &"never")

	_save_condition(&"frightened", "Frightened",
		"A frightened creature has disadvantage on ability checks and attack rolls while the source of its fear is within line of sight. The creature can't willingly move closer to the source of its fear.",
		[
			{"type": "disadvantage", "on": "ability_checks"},
			{"type": "disadvantage", "on": "attack_rolls"},
			{"type": "cant_approach", "on": "fear_source"},
		], &"save")

	_save_condition(&"grappled", "Grappled",
		"A grappled creature's speed becomes 0, and it can't benefit from any bonus to its speed. The condition ends if the grappler is incapacitated or the creature is moved out of reach.",
		[
			{"type": "speed", "value": 0},
		], &"custom")

	_save_condition(&"incapacitated", "Incapacitated",
		"An incapacitated creature can't take actions or reactions.",
		[
			{"type": "cant_act", "on": "actions"},
			{"type": "cant_act", "on": "reactions"},
		], &"never")

	_save_condition(&"invisible", "Invisible",
		"An invisible creature is impossible to see without the aid of magic or a special sense. The creature's attack rolls have advantage, and attack rolls against the creature have disadvantage.",
		[
			{"type": "advantage", "on": "attack_rolls"},
			{"type": "disadvantage", "on": "attack_rolls_against"},
			{"type": "unseen", "on": "sight"},
		], &"custom")

	_save_condition(&"paralyzed", "Paralyzed",
		"A paralyzed creature is incapacitated and can't move or speak. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage. Any attack that hits is a critical hit if the attacker is within 5 feet.",
		[
			{"type": "incapacitated", "on": "all"},
			{"type": "speed", "value": 0},
			{"type": "auto_fail", "on": "strength_saves"},
			{"type": "auto_fail", "on": "dexterity_saves"},
			{"type": "advantage", "on": "attack_rolls_against"},
			{"type": "auto_crit", "on": "melee_attacks_against"},
		], &"save")

	_save_condition(&"petrified", "Petrified",
		"A petrified creature is transformed into a solid inanimate substance. It is incapacitated, can't move or speak, and is unaware of its surroundings. Attack rolls against it have advantage. It automatically fails Strength and Dexterity saves. It has resistance to all damage and is immune to poison and disease.",
		[
			{"type": "incapacitated", "on": "all"},
			{"type": "speed", "value": 0},
			{"type": "auto_fail", "on": "strength_saves"},
			{"type": "auto_fail", "on": "dexterity_saves"},
			{"type": "advantage", "on": "attack_rolls_against"},
			{"type": "resistance", "on": "all_damage"},
			{"type": "immunity", "on": "poison"},
		], &"never")

	_save_condition(&"poisoned", "Poisoned",
		"A poisoned creature has disadvantage on attack rolls and ability checks.",
		[
			{"type": "disadvantage", "on": "attack_rolls"},
			{"type": "disadvantage", "on": "ability_checks"},
		], &"save")

	_save_condition(&"prone", "Prone",
		"A prone creature's only movement option is to crawl (half speed) unless it stands up. The creature has disadvantage on attack rolls. An attack roll against the creature has advantage if the attacker is within 5 feet; otherwise, the attack roll has disadvantage.",
		[
			{"type": "disadvantage", "on": "attack_rolls"},
			{"type": "advantage", "on": "melee_attacks_against"},
			{"type": "disadvantage", "on": "ranged_attacks_against"},
			{"type": "movement_cost", "value": 2},
		], &"custom")

	_save_condition(&"restrained", "Restrained",
		"A restrained creature's speed becomes 0. Attack rolls against the creature have advantage, and the creature's attack rolls have disadvantage. The creature has disadvantage on Dexterity saving throws.",
		[
			{"type": "speed", "value": 0},
			{"type": "advantage", "on": "attack_rolls_against"},
			{"type": "disadvantage", "on": "attack_rolls"},
			{"type": "disadvantage", "on": "dexterity_saves"},
		], &"save")

	_save_condition(&"stunned", "Stunned",
		"A stunned creature is incapacitated, can't move, and can speak only falteringly. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage.",
		[
			{"type": "incapacitated", "on": "all"},
			{"type": "speed", "value": 0},
			{"type": "auto_fail", "on": "strength_saves"},
			{"type": "auto_fail", "on": "dexterity_saves"},
			{"type": "advantage", "on": "attack_rolls_against"},
		], &"save")

	_save_condition(&"unconscious", "Unconscious",
		"An unconscious creature is incapacitated, can't move or speak, and is unaware of its surroundings. The creature drops whatever it's holding and falls prone. Attack rolls against the creature have advantage. Any attack that hits is a critical hit if the attacker is within 5 feet. The creature automatically fails Strength and Dexterity saving throws.",
		[
			{"type": "incapacitated", "on": "all"},
			{"type": "speed", "value": 0},
			{"type": "auto_fail", "on": "strength_saves"},
			{"type": "auto_fail", "on": "dexterity_saves"},
			{"type": "advantage", "on": "attack_rolls_against"},
			{"type": "auto_crit", "on": "melee_attacks_against"},
			{"type": "prone", "on": "self"},
		], &"save")


func _save_condition(id: StringName, display_name: String, description: String,
		effects: Array, ends_on: StringName, save_ability: StringName = &"", save_dc: int = 0) -> void:
	var c := ConditionData.new()
	c.id = id
	c.display_name = display_name
	c.description = description
	var typed_effects: Array[Dictionary] = []
	for e in effects:
		typed_effects.append(e)
	c.effects = typed_effects
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
		{"name": "Nimble Escape", "description": "The goblin can take the Disengage or Hide action as a bonus action on each of its turns."},
	]
	goblin.actions = [
		{"name": "Scimitar", "type": "melee_attack", "attack_bonus": 4, "reach": 5,
		 "damage": "1d6+2", "damage_type": "slashing",
		 "description": "Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 5 (1d6 + 2) slashing damage."},
		{"name": "Shortbow", "type": "ranged_attack", "attack_bonus": 4, "range_normal": 80, "range_long": 320,
		 "damage": "1d6+2", "damage_type": "piercing",
		 "description": "Ranged Weapon Attack: +4 to hit, range 80/320 ft., one target. Hit: 5 (1d6 + 2) piercing damage."},
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
	skeleton.actions = [
		{"name": "Shortsword", "type": "melee_attack", "attack_bonus": 4, "reach": 5,
		 "damage": "1d6+2", "damage_type": "piercing",
		 "description": "Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 5 (1d6 + 2) piercing damage."},
		{"name": "Shortbow", "type": "ranged_attack", "attack_bonus": 4, "range_normal": 80, "range_long": 320,
		 "damage": "1d6+2", "damage_type": "piercing",
		 "description": "Ranged Weapon Attack: +4 to hit, range 80/320 ft., one target. Hit: 5 (1d6 + 2) piercing damage."},
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
		{"name": "Keen Hearing and Smell", "description": "The wolf has advantage on Wisdom (Perception) checks that rely on hearing or smell."},
		{"name": "Pack Tactics", "description": "The wolf has advantage on an attack roll against a creature if at least one of the wolf's allies is within 5 feet of the creature and the ally isn't incapacitated."},
	]
	wolf.actions = [
		{"name": "Bite", "type": "melee_attack", "attack_bonus": 4, "reach": 5,
		 "damage": "2d4+2", "damage_type": "piercing",
		 "description": "Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 7 (2d4 + 2) piercing damage. If the target is a creature, it must succeed on a DC 11 Strength saving throw or be knocked prone.",
		 "save_dc": 11, "save_ability": "strength", "save_effect": "prone"},
	]
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
		{"name": "Undead Fortitude", "description": "If damage reduces the zombie to 0 hit points, it must make a Constitution saving throw with a DC of 5 + the damage taken, unless the damage is radiant or from a critical hit. On a success, the zombie drops to 1 hit point instead."},
	]
	zombie.actions = [
		{"name": "Slam", "type": "melee_attack", "attack_bonus": 3, "reach": 5,
		 "damage": "1d6+1", "damage_type": "bludgeoning",
		 "description": "Melee Weapon Attack: +3 to hit, reach 5 ft., one target. Hit: 4 (1d6 + 1) bludgeoning damage."},
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
		{"name": "Aggressive", "description": "As a bonus action, the orc can move up to its speed toward a hostile creature that it can see."},
	]
	orc.actions = [
		{"name": "Greataxe", "type": "melee_attack", "attack_bonus": 5, "reach": 5,
		 "damage": "1d12+3", "damage_type": "slashing",
		 "description": "Melee Weapon Attack: +5 to hit, reach 5 ft., one target. Hit: 9 (1d12 + 3) slashing damage."},
		{"name": "Javelin", "type": "ranged_attack", "attack_bonus": 5, "range_normal": 30, "range_long": 120,
		 "damage": "1d6+3", "damage_type": "piercing",
		 "description": "Ranged Weapon Attack: +5 to hit, range 30/120 ft., one target. Hit: 6 (1d6 + 3) piercing damage."},
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
	ogre.actions = [
		{"name": "Greatclub", "type": "melee_attack", "attack_bonus": 6, "reach": 5,
		 "damage": "2d8+4", "damage_type": "bludgeoning",
		 "description": "Melee Weapon Attack: +6 to hit, reach 5 ft., one target. Hit: 13 (2d8 + 4) bludgeoning damage."},
		{"name": "Javelin", "type": "ranged_attack", "attack_bonus": 6, "range_normal": 30, "range_long": 120,
		 "damage": "2d6+4", "damage_type": "piercing",
		 "description": "Ranged Weapon Attack: +6 to hit, range 30/120 ft., one target. Hit: 11 (2d6 + 4) piercing damage."},
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
	var spawns: Array[Dictionary] = [
		{"monster_id": &"goblin", "cell": Vector2i(12, 3), "count": 1},
		{"monster_id": &"goblin", "cell": Vector2i(13, 5), "count": 1},
		{"monster_id": &"goblin", "cell": Vector2i(11, 5), "count": 1},
	]
	enc.monster_spawns = spawns
	enc.difficulty = &"easy"
	enc.grants_xp = true
	_save(enc, "res://data/encounters/test_goblin_ambush.tres")

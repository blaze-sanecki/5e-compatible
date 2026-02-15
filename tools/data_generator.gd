## Tool script that generates all sample .tres data files.
## Run this scene (F6) to populate the data/ directories.
extends Node


func _ready() -> void:
	print("=== Data Generator ===")
	_generate_feats()
	_generate_classes()
	_generate_species()
	_generate_backgrounds()
	_generate_weapons()
	_generate_armor()
	_generate_level_progressions()
	print("=== Generation complete! ===")
	get_tree().quit()


func _save(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Failed to save: %s (error %d)" % [path, err])
	else:
		print("  Saved: %s" % path)


# ===========================================================================
# Feats
# ===========================================================================

func _generate_feats() -> void:
	print("Generating feats...")

	var alert := FeatData.new()
	alert.id = &"alert"
	alert.display_name = "Alert"
	alert.description = "You gain a +5 bonus to initiative. You can't be surprised while you are conscious. Other creatures don't gain advantage on attack rolls against you as a result of being unseen by you."
	alert.category = &"origin"
	alert.effects = [
		{"type": "initiative_bonus", "value": 5},
	]
	_save(alert, "res://data/feats/alert.tres")

	var mi_cleric := FeatData.new()
	mi_cleric.id = &"magic_initiate_cleric"
	mi_cleric.display_name = "Magic Initiate (Cleric)"
	mi_cleric.description = "You learn two cantrips and one 1st-level spell from the Cleric spell list. You can cast the 1st-level spell once per Long Rest without expending a spell slot. Wisdom is your spellcasting ability for these spells."
	mi_cleric.category = &"origin"
	mi_cleric.effects = [
		{"type": "cantrips", "value": 2, "class": "cleric"},
		{"type": "spell", "value": 1, "class": "cleric", "level": 1},
	]
	_save(mi_cleric, "res://data/feats/magic_initiate_cleric.tres")

	var mi_wizard := FeatData.new()
	mi_wizard.id = &"magic_initiate_wizard"
	mi_wizard.display_name = "Magic Initiate (Wizard)"
	mi_wizard.description = "You learn two cantrips and one 1st-level spell from the Wizard spell list. You can cast the 1st-level spell once per Long Rest without expending a spell slot. Intelligence is your spellcasting ability for these spells."
	mi_wizard.category = &"origin"
	mi_wizard.effects = [
		{"type": "cantrips", "value": 2, "class": "wizard"},
		{"type": "spell", "value": 1, "class": "wizard", "level": 1},
	]
	_save(mi_wizard, "res://data/feats/magic_initiate_wizard.tres")

	var skilled := FeatData.new()
	skilled.id = &"skilled"
	skilled.display_name = "Skilled"
	skilled.description = "You gain proficiency in any combination of three skills or tools of your choice."
	skilled.category = &"origin"
	skilled.effects = [
		{"type": "skill_proficiency", "value": 3},
	]
	_save(skilled, "res://data/feats/skilled.tres")


# ===========================================================================
# Classes
# ===========================================================================

func _generate_classes() -> void:
	print("Generating classes...")

	# --- Fighter ---
	var fighter := ClassData.new()
	fighter.id = &"fighter"
	fighter.display_name = "Fighter"
	fighter.description = "A master of martial combat, skilled with a variety of weapons and armor."
	fighter.hit_die = 10
	fighter.primary_ability = &"strength"
	fighter.saving_throw_proficiencies = [&"strength", &"constitution"]
	fighter.armor_proficiencies = [&"light", &"medium", &"heavy", &"shield"]
	fighter.weapon_proficiencies = [&"simple", &"martial"]
	fighter.skill_choices = [&"acrobatics", &"animal_handling", &"athletics", &"history", &"insight", &"intimidation", &"perception", &"survival"]
	fighter.num_skill_choices = 2
	fighter.starting_equipment_options = ["Chain Mail or Leather Armor", "Longsword and Shield or two Martial Weapons", "Light Crossbow and 20 bolts or two Handaxes", "Dungeoneer's Pack or Explorer's Pack"]
	fighter.is_spellcaster = false
	fighter.subclass_level = 3
	fighter.class_features = [
		{"level": 1, "name": "Fighting Style", "description": "You adopt a particular style of fighting as your specialty."},
		{"level": 1, "name": "Second Wind", "description": "You have a limited well of stamina. On your turn, you can use a Bonus Action to regain hit points equal to 1d10 + your Fighter level. Once you use this feature, you must finish a Short or Long Rest before you can use it again."},
		{"level": 2, "name": "Action Surge", "description": "You can push yourself beyond your normal limits for a moment. On your turn, you can take one additional action. Once you use this feature, you must finish a Short or Long Rest before you can use it again."},
		{"level": 3, "name": "Subclass", "description": "Choose a martial archetype that you strive to emulate in your combat styles and techniques."},
		{"level": 4, "name": "Ability Score Improvement", "description": "You can increase one ability score by 2, or two ability scores by 1. You can't increase an ability score above 20. Alternatively, you can take a feat."},
		{"level": 5, "name": "Extra Attack", "description": "You can attack twice, instead of once, whenever you take the Attack action on your turn."},
	]
	_save(fighter, "res://data/classes/fighter.tres")

	# --- Wizard ---
	var wizard := ClassData.new()
	wizard.id = &"wizard"
	wizard.display_name = "Wizard"
	wizard.description = "A scholarly magic-user capable of manipulating the structures of reality."
	wizard.hit_die = 6
	wizard.primary_ability = &"intelligence"
	wizard.saving_throw_proficiencies = [&"intelligence", &"wisdom"]
	wizard.armor_proficiencies = []
	wizard.weapon_proficiencies = [&"dagger", &"dart", &"sling", &"quarterstaff", &"light_crossbow"]
	wizard.skill_choices = [&"arcana", &"history", &"insight", &"investigation", &"medicine", &"religion"]
	wizard.num_skill_choices = 2
	wizard.starting_equipment_options = ["Quarterstaff or Dagger", "Component Pouch or Arcane Focus", "Scholar's Pack or Explorer's Pack", "Spellbook"]
	wizard.spellcasting_ability = &"intelligence"
	wizard.is_spellcaster = true
	wizard.subclass_level = 2
	wizard.class_features = [
		{"level": 1, "name": "Spellcasting", "description": "As a student of arcane magic, you have a spellbook containing spells that show the first glimmerings of your true power. You know three cantrips and have a spellbook with six 1st-level wizard spells."},
		{"level": 1, "name": "Arcane Recovery", "description": "Once per day when you finish a Short Rest, you can recover expended spell slots with a combined level equal to or less than half your wizard level (rounded up)."},
		{"level": 2, "name": "Subclass", "description": "Choose an arcane tradition that shapes your practice of magic."},
		{"level": 3, "name": "Cantrip Formulas", "description": "You have scribed a set of arcane formulas in your spellbook that you can use to formulate a cantrip in your mind."},
		{"level": 4, "name": "Ability Score Improvement", "description": "You can increase one ability score by 2, or two ability scores by 1. You can't increase an ability score above 20. Alternatively, you can take a feat."},
		{"level": 5, "name": "Memorize Spell", "description": "You can prepare one additional spell from your spellbook."},
	]
	_save(wizard, "res://data/classes/wizard.tres")

	# --- Rogue ---
	var rogue := ClassData.new()
	rogue.id = &"rogue"
	rogue.display_name = "Rogue"
	rogue.description = "A scoundrel who uses stealth and trickery to overcome obstacles and enemies."
	rogue.hit_die = 8
	rogue.primary_ability = &"dexterity"
	rogue.saving_throw_proficiencies = [&"dexterity", &"intelligence"]
	rogue.armor_proficiencies = [&"light"]
	rogue.weapon_proficiencies = [&"simple", &"hand_crossbow", &"longsword", &"rapier", &"shortsword"]
	rogue.skill_choices = [&"acrobatics", &"athletics", &"deception", &"insight", &"intimidation", &"investigation", &"perception", &"performance", &"persuasion", &"sleight_of_hand", &"stealth"]
	rogue.num_skill_choices = 4
	rogue.starting_equipment_options = ["Rapier or Shortsword", "Shortbow and 20 arrows or Shortsword", "Burglar's Pack, Dungeoneer's Pack, or Explorer's Pack", "Leather Armor, two Daggers, and Thieves' Tools"]
	rogue.is_spellcaster = false
	rogue.subclass_level = 3
	rogue.class_features = [
		{"level": 1, "name": "Expertise", "description": "Choose two of your skill proficiencies or one skill proficiency and Thieves' Tools. Your proficiency bonus is doubled for any ability check you make with the chosen proficiencies."},
		{"level": 1, "name": "Sneak Attack", "description": "Once per turn, you can deal an extra 1d6 damage to one creature you hit with an attack if you have advantage on the attack roll. The extra damage increases as you gain levels. The attack must use a finesse or a ranged weapon."},
		{"level": 1, "name": "Thieves' Cant", "description": "You have learned thieves' cant, a secret mix of dialect, jargon, and code that allows you to hide messages in seemingly normal conversation."},
		{"level": 2, "name": "Cunning Action", "description": "You can take a Bonus Action on each of your turns in combat to Dash, Disengage, or Hide."},
		{"level": 3, "name": "Subclass", "description": "Choose a roguish archetype that you emulate in your activities."},
		{"level": 3, "name": "Steady Aim", "description": "As a Bonus Action, you give yourself advantage on your next attack roll on the current turn if you haven't moved during this turn."},
		{"level": 4, "name": "Ability Score Improvement", "description": "You can increase one ability score by 2, or two ability scores by 1. You can't increase an ability score above 20. Alternatively, you can take a feat."},
		{"level": 5, "name": "Uncanny Dodge", "description": "When an attacker that you can see hits you with an attack, you can use your Reaction to halve the attack's damage against you."},
	]
	_save(rogue, "res://data/classes/rogue.tres")

	# --- Cleric ---
	var cleric := ClassData.new()
	cleric.id = &"cleric"
	cleric.display_name = "Cleric"
	cleric.description = "A priestly champion who wields divine magic in service of a higher power."
	cleric.hit_die = 8
	cleric.primary_ability = &"wisdom"
	cleric.saving_throw_proficiencies = [&"wisdom", &"charisma"]
	cleric.armor_proficiencies = [&"light", &"medium", &"shield"]
	cleric.weapon_proficiencies = [&"simple"]
	cleric.skill_choices = [&"history", &"insight", &"medicine", &"persuasion", &"religion"]
	cleric.num_skill_choices = 2
	cleric.starting_equipment_options = ["Mace or Warhammer (if proficient)", "Scale Mail, Leather Armor, or Chain Mail (if proficient)", "Light Crossbow and 20 bolts or any Simple Weapon", "Priest's Pack or Explorer's Pack", "Shield and Holy Symbol"]
	cleric.spellcasting_ability = &"wisdom"
	cleric.is_spellcaster = true
	cleric.subclass_level = 1
	cleric.class_features = [
		{"level": 1, "name": "Spellcasting", "description": "As a conduit for divine power, you can cast cleric spells. You know three cantrips and can prepare a number of spells equal to your Wisdom modifier + your Cleric level."},
		{"level": 1, "name": "Divine Domain", "description": "Choose one domain related to your deity. Your domain grants you additional spells and features."},
		{"level": 2, "name": "Channel Divinity", "description": "You gain the ability to channel divine energy directly from your deity, using that energy to fuel magical effects. You start with Turn Undead and one effect determined by your domain. You can use Channel Divinity once between rests."},
		{"level": 2, "name": "Turn Undead", "description": "As an action, you present your holy symbol and speak a prayer censuring the undead. Each undead within 30 feet that can see or hear you must make a Wisdom saving throw or be turned for 1 minute."},
		{"level": 4, "name": "Ability Score Improvement", "description": "You can increase one ability score by 2, or two ability scores by 1. You can't increase an ability score above 20. Alternatively, you can take a feat."},
		{"level": 5, "name": "Destroy Undead", "description": "When an undead fails its saving throw against your Turn Undead feature, the creature is instantly destroyed if its challenge rating is at or below 1/2."},
	]
	_save(cleric, "res://data/classes/cleric.tres")


# ===========================================================================
# Species
# ===========================================================================

func _generate_species() -> void:
	print("Generating species...")

	var human := SpeciesData.new()
	human.id = &"human"
	human.display_name = "Human"
	human.description = "Humans are the most adaptable and ambitious people among the common races. Whatever drives them, humans are the innovators, the achievers, and the pioneers of the worlds."
	human.creature_type = &"humanoid"
	human.size = &"medium"
	human.base_speed = 30
	human.darkvision_range = 0
	human.languages = [&"common"]
	human.traits = [
		{"name": "Resourceful", "description": "You gain Heroic Inspiration whenever you finish a Long Rest."},
		{"name": "Skillful", "description": "You gain proficiency in one skill of your choice."},
		{"name": "Versatile", "description": "You gain an Origin feat of your choice."},
	]
	_save(human, "res://data/species/human.tres")

	var elf := SpeciesData.new()
	elf.id = &"elf"
	elf.display_name = "Elf"
	elf.description = "Elves are a magical people of otherworldly grace, living in places of ethereal beauty, in the midst of ancient forests or in silvery spires glittering with faerie light."
	elf.creature_type = &"humanoid"
	elf.size = &"medium"
	elf.base_speed = 30
	elf.darkvision_range = 60
	elf.languages = [&"common", &"elvish"]
	elf.traits = [
		{"name": "Darkvision", "description": "You can see in dim light within 60 feet of you as if it were bright light, and in darkness as if it were dim light."},
		{"name": "Keen Senses", "description": "You have proficiency in the Perception skill."},
		{"name": "Fey Ancestry", "description": "You have advantage on saving throws against being charmed, and magic can't put you to sleep."},
		{"name": "Trance", "description": "Elves do not sleep. Instead they meditate deeply for 4 hours a day. After resting this way, you gain the same benefit a human does from 8 hours of sleep."},
	]
	_save(elf, "res://data/species/elf.tres")

	var dwarf := SpeciesData.new()
	dwarf.id = &"dwarf"
	dwarf.display_name = "Dwarf"
	dwarf.description = "Bold and hardy, dwarves are known as skilled warriors, miners, and workers of stone and metal. Though they stand well under 5 feet tall, dwarves are so broad and compact that they can weigh as much as a human standing nearly two feet taller."
	dwarf.creature_type = &"humanoid"
	dwarf.size = &"medium"
	dwarf.base_speed = 25
	dwarf.darkvision_range = 60
	dwarf.resistances = [&"poison"]
	dwarf.languages = [&"common", &"dwarvish"]
	dwarf.traits = [
		{"name": "Darkvision", "description": "You can see in dim light within 60 feet of you as if it were bright light, and in darkness as if it were dim light."},
		{"name": "Dwarven Resilience", "description": "You have resistance to poison damage. You also have advantage on saving throws against the poisoned condition."},
		{"name": "Dwarven Toughness", "description": "Your hit point maximum increases by 1, and it increases by 1 every time you gain a level."},
		{"name": "Stonecunning", "description": "Whenever you make an Intelligence (History) check related to the origin of stonework, you are considered proficient and add double your proficiency bonus to the check."},
	]
	_save(dwarf, "res://data/species/dwarf.tres")

	var halfling := SpeciesData.new()
	halfling.id = &"halfling"
	halfling.display_name = "Halfling"
	halfling.description = "The comforts of home are the goals of most halflings' lives: a place to settle in peace and quiet, far from marauding monsters and clashing armies."
	halfling.creature_type = &"humanoid"
	halfling.size = &"small"
	halfling.base_speed = 30
	halfling.darkvision_range = 0
	halfling.languages = [&"common", &"halfling"]
	halfling.traits = [
		{"name": "Brave", "description": "You have advantage on saving throws against being frightened."},
		{"name": "Halfling Nimbleness", "description": "You can move through the space of any creature that is of a size larger than yours."},
		{"name": "Lucky", "description": "When you roll a 1 on the d20 for an attack roll, ability check, or saving throw, you can reroll the die and must use the new roll."},
		{"name": "Naturally Stealthy", "description": "You can attempt to hide even when you are obscured only by a creature that is at least one size larger than you."},
	]
	_save(halfling, "res://data/species/halfling.tres")


# ===========================================================================
# Backgrounds
# ===========================================================================

func _generate_backgrounds() -> void:
	print("Generating backgrounds...")

	var acolyte := BackgroundData.new()
	acolyte.id = &"acolyte"
	acolyte.display_name = "Acolyte"
	acolyte.description = "You devoted yourself to service in a temple, either nestled in a town or secluded in a sacred grove. You performed sacred rites and learned the lore of your faith."
	acolyte.skill_proficiencies = [&"insight", &"religion"]
	acolyte.tool_proficiencies = [&"calligrapher_supplies"]
	acolyte.languages_count = 1
	acolyte.starting_gold = 8
	acolyte.ability_score_increases = {"wisdom": 2, "intelligence": 1, "constitution": 1}
	acolyte.origin_feat = &"magic_initiate_cleric"
	_save(acolyte, "res://data/backgrounds/acolyte.tres")

	var criminal := BackgroundData.new()
	criminal.id = &"criminal"
	criminal.display_name = "Criminal"
	criminal.description = "You eked out a living by breaking the law. You have contacts within the criminal underworld and a knack for getting away with crimes."
	criminal.skill_proficiencies = [&"sleight_of_hand", &"stealth"]
	criminal.tool_proficiencies = [&"thieves_tools"]
	criminal.starting_gold = 16
	criminal.ability_score_increases = {"dexterity": 2, "constitution": 1, "intelligence": 1}
	criminal.origin_feat = &"alert"
	_save(criminal, "res://data/backgrounds/criminal.tres")

	var noble := BackgroundData.new()
	noble.id = &"noble"
	noble.display_name = "Noble"
	noble.description = "You were raised in a family among the social elite. Your family may be old money or newly wealthy, but either way you grew up surrounded by power and privilege."
	noble.skill_proficiencies = [&"history", &"persuasion"]
	noble.tool_proficiencies = [&"gaming_set"]
	noble.languages_count = 1
	noble.starting_gold = 28
	noble.ability_score_increases = {"charisma": 2, "intelligence": 1, "strength": 1}
	noble.origin_feat = &"skilled"
	_save(noble, "res://data/backgrounds/noble.tres")

	var sage := BackgroundData.new()
	sage.id = &"sage"
	sage.display_name = "Sage"
	sage.description = "You spent years learning the lore of the multiverse. You scoured manuscripts, studied scrolls, and listened to the greatest experts on the subjects that interest you."
	sage.skill_proficiencies = [&"arcana", &"history"]
	sage.tool_proficiencies = [&"calligrapher_supplies"]
	sage.languages_count = 1
	sage.starting_gold = 8
	sage.ability_score_increases = {"intelligence": 2, "wisdom": 1, "constitution": 1}
	sage.origin_feat = &"magic_initiate_wizard"
	_save(sage, "res://data/backgrounds/sage.tres")


# ===========================================================================
# Weapons
# ===========================================================================

func _generate_weapons() -> void:
	print("Generating weapons...")

	# --- Simple Melee ---
	_save_weapon(&"club", "Club", "simple", 1, 4, &"bludgeoning", [&"light"], 5, 0, 0.1, 2.0)
	_save_weapon(&"dagger", "Dagger", "simple", 1, 4, &"piercing", [&"finesse", &"light", &"thrown"], 5, 0, 2.0, 1.0, 20, 60)
	_save_weapon(&"greatclub", "Greatclub", "simple", 1, 8, &"bludgeoning", [&"two_handed"], 5, 0, 0.2, 10.0)
	_save_weapon(&"handaxe", "Handaxe", "simple", 1, 6, &"slashing", [&"light", &"thrown"], 5, 0, 5.0, 2.0, 20, 60)
	_save_weapon(&"javelin", "Javelin", "simple", 1, 6, &"piercing", [&"thrown"], 5, 0, 0.5, 2.0, 30, 120)
	_save_weapon(&"mace", "Mace", "simple", 1, 6, &"bludgeoning", [], 5, 0, 5.0, 4.0)
	_save_weapon(&"quarterstaff", "Quarterstaff", "simple", 1, 6, &"bludgeoning", [&"versatile"], 5, 0, 0.2, 4.0, 0, 0, 1, 8)
	_save_weapon(&"spear", "Spear", "simple", 1, 6, &"piercing", [&"thrown", &"versatile"], 5, 0, 1.0, 3.0, 20, 60, 1, 8)

	# --- Simple Ranged ---
	_save_weapon(&"light_crossbow", "Light Crossbow", "simple", 1, 8, &"piercing", [&"ammunition", &"loading", &"two_handed"], 80, 320, 25.0, 5.0)
	_save_weapon(&"shortbow", "Shortbow", "simple", 1, 6, &"piercing", [&"ammunition", &"two_handed"], 80, 320, 25.0, 2.0)

	# --- Martial Melee ---
	_save_weapon(&"greatsword", "Greatsword", "martial", 2, 6, &"slashing", [&"heavy", &"two_handed"], 5, 0, 50.0, 6.0)
	_save_weapon(&"longsword", "Longsword", "martial", 1, 8, &"slashing", [&"versatile"], 5, 0, 15.0, 3.0, 0, 0, 1, 10)
	_save_weapon(&"rapier", "Rapier", "martial", 1, 8, &"piercing", [&"finesse"], 5, 0, 25.0, 2.0)
	_save_weapon(&"shortsword", "Shortsword", "martial", 1, 6, &"piercing", [&"finesse", &"light"], 5, 0, 10.0, 2.0)

	# --- Martial Ranged ---
	_save_weapon(&"hand_crossbow", "Hand Crossbow", "martial", 1, 6, &"piercing", [&"ammunition", &"light", &"loading"], 30, 120, 75.0, 3.0)
	_save_weapon(&"longbow", "Longbow", "martial", 1, 8, &"piercing", [&"ammunition", &"heavy", &"two_handed"], 150, 600, 50.0, 2.0)


func _save_weapon(
	id: StringName, display_name: String, category: String,
	dice_count: int, dice_size: int, dmg_type: StringName,
	properties: Array, range_normal: int, range_long: int,
	cost: float, weight: float,
	thrown_normal: int = 0, thrown_long: int = 0,
	versatile_count: int = 0, versatile_size: int = 0,
) -> void:
	var w := WeaponData.new()
	w.id = id
	w.display_name = display_name
	w.weapon_category = StringName(category)
	w.cost_gp = cost
	w.weight = weight

	var dmg := DamageRoll.new()
	dmg.dice_count = dice_count
	dmg.dice_size = dice_size
	dmg.damage_type = dmg_type
	w.damage = dmg

	var typed_props: Array[StringName] = []
	for p in properties:
		typed_props.append(p)
	w.properties = typed_props

	# Keep melee range for thrown weapons so is_melee() stays correct.
	# The thrown property + range_long signals ranged capability via is_ranged().
	w.range_normal = range_normal
	w.range_long = thrown_long if thrown_long > 0 else range_long

	if versatile_count > 0:
		var vd := DamageRoll.new()
		vd.dice_count = versatile_count
		vd.dice_size = versatile_size
		vd.damage_type = dmg_type
		w.versatile_damage = vd

	_save(w, "res://data/equipment/%s.tres" % id)


# ===========================================================================
# Armor
# ===========================================================================

func _generate_armor() -> void:
	print("Generating armor...")

	# Light
	_save_armor(&"padded", "Padded", "light", 11, true, -1, 0, true, 5.0, 8.0)
	_save_armor(&"leather", "Leather", "light", 11, true, -1, 0, false, 10.0, 10.0)
	_save_armor(&"studded_leather", "Studded Leather", "light", 12, true, -1, 0, false, 45.0, 13.0)

	# Medium
	_save_armor(&"hide", "Hide", "medium", 12, true, 2, 0, false, 10.0, 12.0)
	_save_armor(&"chain_shirt", "Chain Shirt", "medium", 13, true, 2, 0, false, 50.0, 20.0)
	_save_armor(&"scale_mail", "Scale Mail", "medium", 14, true, 2, 0, true, 50.0, 45.0)
	_save_armor(&"breastplate", "Breastplate", "medium", 14, true, 2, 0, false, 400.0, 20.0)
	_save_armor(&"half_plate", "Half Plate", "medium", 15, true, 2, 0, true, 750.0, 40.0)

	# Heavy
	_save_armor(&"ring_mail", "Ring Mail", "heavy", 14, false, 0, 0, true, 30.0, 40.0)
	_save_armor(&"chain_mail", "Chain Mail", "heavy", 16, false, 0, 13, true, 75.0, 55.0)
	_save_armor(&"splint", "Splint", "heavy", 17, false, 0, 15, true, 200.0, 60.0)
	_save_armor(&"plate", "Plate", "heavy", 18, false, 0, 15, true, 1500.0, 65.0)

	# Shield
	_save_armor(&"shield", "Shield", "shield", 2, false, 0, 0, false, 10.0, 6.0)


func _save_armor(
	id: StringName, display_name: String, category: String,
	base_ac: int, add_dex: bool, max_dex: int,
	str_req: int, stealth_dis: bool,
	cost: float, weight: float,
) -> void:
	var a := ArmorData.new()
	a.id = id
	a.display_name = display_name
	a.armor_category = StringName(category)
	a.base_ac = base_ac
	a.add_dex = add_dex
	a.max_dex_bonus = max_dex
	a.strength_requirement = str_req
	a.stealth_disadvantage = stealth_dis
	a.cost_gp = cost
	a.weight = weight
	_save(a, "res://data/equipment/%s.tres" % id)


# ===========================================================================
# Level Progressions
# ===========================================================================

func _generate_level_progressions() -> void:
	print("Generating level progressions...")
	_generate_fighter_progression()
	_generate_wizard_progression()
	_generate_rogue_progression()
	_generate_cleric_progression()


func _prof(level: int) -> int:
	@warning_ignore("integer_division")
	return int(floor(float(level - 1) / 4.0)) + 2


func _generate_fighter_progression() -> void:
	var lp := LevelProgression.new()
	lp.class_id = &"fighter"
	lp.levels = []
	for lvl in range(1, 21):
		var entry: Dictionary = {
			"level": lvl,
			"proficiency_bonus": _prof(lvl),
			"features": [],
		}
		match lvl:
			1: entry["features"] = [
				{"name": "Fighting Style", "description": "You adopt a style of fighting as your specialty."},
				{"name": "Second Wind", "description": "Regain 1d10 + Fighter level HP as a Bonus Action (1/rest)."},
			]
			2: entry["features"] = [
				{"name": "Action Surge", "description": "Take one additional action on your turn (1/rest)."},
			]
			3: entry["features"] = [{"name": "Subclass Feature", "description": "Martial archetype feature."}]
			4: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			5: entry["features"] = [{"name": "Extra Attack", "description": "Attack twice when you take the Attack action."}]
			6: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			7: entry["features"] = [{"name": "Subclass Feature", "description": "Martial archetype feature."}]
			8: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			9: entry["features"] = [{"name": "Indomitable", "description": "Reroll a failed saving throw (1/long rest)."}]
			10: entry["features"] = [{"name": "Subclass Feature", "description": "Martial archetype feature."}]
			11: entry["features"] = [{"name": "Extra Attack (2)", "description": "Attack three times when you take the Attack action."}]
			12: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			13: entry["features"] = [{"name": "Indomitable (2)", "description": "Use Indomitable twice between long rests."}]
			14: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			15: entry["features"] = [{"name": "Subclass Feature", "description": "Martial archetype feature."}]
			16: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			17: entry["features"] = [
				{"name": "Action Surge (2)", "description": "Use Action Surge twice between rests."},
				{"name": "Indomitable (3)", "description": "Use Indomitable three times between long rests."},
			]
			18: entry["features"] = [{"name": "Subclass Feature", "description": "Martial archetype feature."}]
			19: entry["features"] = [{"name": "Epic Boon", "description": "Gain an Epic Boon feat."}]
			20: entry["features"] = [{"name": "Extra Attack (3)", "description": "Attack four times when you take the Attack action."}]
		lp.levels.append(entry)
	_save(lp, "res://data/tables/fighter_progression.tres")


func _generate_wizard_progression() -> void:
	var lp := LevelProgression.new()
	lp.class_id = &"wizard"
	var full_caster_slots: Array = [
		[2, 0, 0, 0, 0, 0, 0, 0, 0],
		[3, 0, 0, 0, 0, 0, 0, 0, 0],
		[4, 2, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 2, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 1, 0, 0, 0, 0, 0],
		[4, 3, 3, 2, 0, 0, 0, 0, 0],
		[4, 3, 3, 3, 1, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 1],
		[4, 3, 3, 3, 3, 1, 1, 1, 1],
		[4, 3, 3, 3, 3, 2, 1, 1, 1],
		[4, 3, 3, 3, 3, 2, 2, 1, 1],
	]
	lp.levels = []
	for lvl in range(1, 21):
		var entry: Dictionary = {
			"level": lvl,
			"proficiency_bonus": _prof(lvl),
			"features": [],
			"spell_slots": full_caster_slots[lvl - 1],
		}
		match lvl:
			1: entry["features"] = [
				{"name": "Spellcasting", "description": "Cast wizard spells using Intelligence."},
				{"name": "Arcane Recovery", "description": "Recover spell slots on a short rest (combined level <= half wizard level)."},
			]
			2: entry["features"] = [{"name": "Subclass Feature", "description": "Arcane tradition feature."}]
			3: entry["features"] = [{"name": "Cantrip Formulas", "description": "Replace a cantrip when you finish a long rest."}]
			4: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			5: entry["features"] = [{"name": "Memorize Spell", "description": "Prepare one additional spell."}]
			6: entry["features"] = [{"name": "Subclass Feature", "description": "Arcane tradition feature."}]
			8: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			10: entry["features"] = [{"name": "Subclass Feature", "description": "Arcane tradition feature."}]
			12: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			14: entry["features"] = [{"name": "Subclass Feature", "description": "Arcane tradition feature."}]
			16: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			18: entry["features"] = [{"name": "Spell Mastery", "description": "Cast a 1st and 2nd level spell at will."}]
			19: entry["features"] = [{"name": "Epic Boon", "description": "Gain an Epic Boon feat."}]
			20: entry["features"] = [{"name": "Signature Spells", "description": "Two 3rd-level spells are always prepared and can be cast once at 3rd level without a slot."}]
		lp.levels.append(entry)
	_save(lp, "res://data/tables/wizard_progression.tres")


func _generate_rogue_progression() -> void:
	var lp := LevelProgression.new()
	lp.class_id = &"rogue"
	lp.levels = []
	for lvl in range(1, 21):
		@warning_ignore("integer_division")
		var sneak_dice: int = int(ceil(float(lvl) / 2.0))
		var entry: Dictionary = {
			"level": lvl,
			"proficiency_bonus": _prof(lvl),
			"features": [],
			"sneak_attack_dice": sneak_dice,
		}
		match lvl:
			1: entry["features"] = [
				{"name": "Expertise", "description": "Double proficiency bonus for two chosen skill proficiencies."},
				{"name": "Sneak Attack", "description": "Deal extra %dd6 damage with finesse/ranged weapons when you have advantage." % sneak_dice},
				{"name": "Thieves' Cant", "description": "A secret language used among rogues."},
			]
			2: entry["features"] = [{"name": "Cunning Action", "description": "Dash, Disengage, or Hide as a Bonus Action."}]
			3: entry["features"] = [
				{"name": "Subclass Feature", "description": "Roguish archetype feature."},
				{"name": "Steady Aim", "description": "Gain advantage on next attack as Bonus Action (if you haven't moved)."},
			]
			4: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			5: entry["features"] = [{"name": "Uncanny Dodge", "description": "Halve attack damage as a Reaction."}]
			6: entry["features"] = [{"name": "Expertise (2)", "description": "Double proficiency for two more skill proficiencies."}]
			7: entry["features"] = [{"name": "Evasion", "description": "Take no damage on a successful DEX save, half on a failure."}]
			8: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			9: entry["features"] = [{"name": "Subclass Feature", "description": "Roguish archetype feature."}]
			10: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			11: entry["features"] = [{"name": "Reliable Talent", "description": "Minimum 10 on proficient ability checks."}]
			12: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			13: entry["features"] = [{"name": "Subclass Feature", "description": "Roguish archetype feature."}]
			14: entry["features"] = [{"name": "Blindsense", "description": "Know location of hidden creatures within 10 feet."}]
			15: entry["features"] = [{"name": "Slippery Mind", "description": "Proficiency in Wisdom saving throws."}]
			16: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			17: entry["features"] = [{"name": "Subclass Feature", "description": "Roguish archetype feature."}]
			18: entry["features"] = [{"name": "Elusive", "description": "No attack roll has advantage against you unless you're incapacitated."}]
			19: entry["features"] = [{"name": "Epic Boon", "description": "Gain an Epic Boon feat."}]
			20: entry["features"] = [{"name": "Stroke of Luck", "description": "Turn a miss into a hit or a failed check into a 20 (1/rest)."}]
		lp.levels.append(entry)
	_save(lp, "res://data/tables/rogue_progression.tres")


func _generate_cleric_progression() -> void:
	var lp := LevelProgression.new()
	lp.class_id = &"cleric"
	var full_caster_slots: Array = [
		[2, 0, 0, 0, 0, 0, 0, 0, 0],
		[3, 0, 0, 0, 0, 0, 0, 0, 0],
		[4, 2, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 2, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 1, 0, 0, 0, 0, 0],
		[4, 3, 3, 2, 0, 0, 0, 0, 0],
		[4, 3, 3, 3, 1, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 1],
		[4, 3, 3, 3, 3, 1, 1, 1, 1],
		[4, 3, 3, 3, 3, 2, 1, 1, 1],
		[4, 3, 3, 3, 3, 2, 2, 1, 1],
	]
	lp.levels = []
	for lvl in range(1, 21):
		var entry: Dictionary = {
			"level": lvl,
			"proficiency_bonus": _prof(lvl),
			"features": [],
			"spell_slots": full_caster_slots[lvl - 1],
		}
		match lvl:
			1: entry["features"] = [
				{"name": "Spellcasting", "description": "Cast cleric spells using Wisdom."},
				{"name": "Divine Domain", "description": "Choose a divine domain that grants bonus spells and features."},
			]
			2: entry["features"] = [
				{"name": "Channel Divinity", "description": "Channel divine energy for magical effects (1/rest)."},
				{"name": "Turn Undead", "description": "Force undead within 30 ft to flee on a failed WIS save."},
			]
			3: entry["features"] = [{"name": "Domain Feature", "description": "Domain-specific feature."}]
			4: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			5: entry["features"] = [{"name": "Destroy Undead (CR 1/2)", "description": "Destroy undead of CR 1/2 or lower on failed Turn Undead save."}]
			6: entry["features"] = [
				{"name": "Channel Divinity (2)", "description": "Use Channel Divinity twice between rests."},
				{"name": "Domain Feature", "description": "Domain-specific feature."},
			]
			8: entry["features"] = [
				{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."},
				{"name": "Destroy Undead (CR 1)", "description": "Destroy undead of CR 1 or lower."},
				{"name": "Domain Feature", "description": "Domain-specific feature."},
			]
			10: entry["features"] = [{"name": "Divine Intervention", "description": "Call on your deity to intervene (percentage chance = cleric level)."}]
			11: entry["features"] = [{"name": "Destroy Undead (CR 2)", "description": "Destroy undead of CR 2 or lower."}]
			12: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			14: entry["features"] = [{"name": "Destroy Undead (CR 3)", "description": "Destroy undead of CR 3 or lower."}]
			16: entry["features"] = [{"name": "Ability Score Improvement", "description": "Increase ability scores or take a feat."}]
			17: entry["features"] = [
				{"name": "Destroy Undead (CR 4)", "description": "Destroy undead of CR 4 or lower."},
				{"name": "Domain Feature", "description": "Domain-specific feature."},
			]
			18: entry["features"] = [{"name": "Channel Divinity (3)", "description": "Use Channel Divinity three times between rests."}]
			19: entry["features"] = [{"name": "Epic Boon", "description": "Gain an Epic Boon feat."}]
			20: entry["features"] = [{"name": "Divine Intervention (Guaranteed)", "description": "Divine Intervention automatically succeeds."}]
		lp.levels.append(entry)
	_save(lp, "res://data/tables/cleric_progression.tres")

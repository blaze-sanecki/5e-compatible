class_name CharacterCreator
extends RefCounted

## Pure logic for building a character step by step.
## Holds creation state, validates each step, and assembles a final CharacterData.

## Standard Array ability scores (2024 SRD).
const STANDARD_ARRAY: Array[int] = [15, 14, 13, 12, 10, 8]

## Point Buy defaults.
const POINT_BUY_BUDGET: int = 27
const POINT_BUY_MIN: int = 8
const POINT_BUY_MAX: int = 15

## Costs per score in point buy.
const POINT_BUY_COSTS: Dictionary = {
	8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9,
}

## Default starting equipment per class.
const DEFAULT_EQUIPMENT: Dictionary = {
	"fighter": ["chain_mail", "longsword", "shield", "light_crossbow"],
	"wizard": ["quarterstaff", "dagger"],
	"rogue": ["leather", "rapier", "shortsword", "shortbow", "dagger", "dagger"],
	"cleric": ["scale_mail", "mace", "shield", "light_crossbow"],
}

# ---------------------------------------------------------------------------
# Creation state
# ---------------------------------------------------------------------------

var chosen_class: ClassData
var chosen_species: SpeciesData
var chosen_background: BackgroundData
var ability_scores: AbilityScores
var chosen_skills: Array[StringName] = []
var chosen_equipment_ids: Array[StringName] = []
var character_name: String = ""

## Which method the player used for ability scores.
enum ScoreMethod { STANDARD_ARRAY, POINT_BUY, ROLL }
var score_method: ScoreMethod = ScoreMethod.STANDARD_ARRAY


# ---------------------------------------------------------------------------
# Step setters
# ---------------------------------------------------------------------------

func set_class(class_data: ClassData) -> void:
	chosen_class = class_data


func set_species(species_data: SpeciesData) -> void:
	chosen_species = species_data


func set_background(background_data: BackgroundData) -> void:
	chosen_background = background_data


func set_ability_scores(scores: AbilityScores) -> void:
	ability_scores = scores


func set_skills(skills: Array[StringName]) -> void:
	chosen_skills = skills


func set_equipment(equipment_ids: Array[StringName]) -> void:
	chosen_equipment_ids = equipment_ids


func set_name(p_name: String) -> void:
	character_name = p_name


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

func is_class_valid() -> bool:
	return chosen_class != null


func is_species_valid() -> bool:
	return chosen_species != null


func is_background_valid() -> bool:
	return chosen_background != null


func are_scores_valid() -> bool:
	if ability_scores == null:
		return false
	# Every score must be at least 3 and at most 20.
	for ability in AbilityScores.ABILITIES:
		var s: int = ability_scores.get_score(ability)
		if s < 3 or s > 20:
			return false
	return true


func are_skills_valid() -> bool:
	# Must have chosen exactly the right number of class skills.
	var required: int = _get_total_skill_count()
	return chosen_skills.size() == required


func is_name_valid() -> bool:
	return character_name.strip_edges().length() > 0


func is_complete() -> bool:
	return is_class_valid() and is_species_valid() and is_background_valid() \
		and are_scores_valid() and are_skills_valid() and is_name_valid()


# ---------------------------------------------------------------------------
# Ability score generation helpers
# ---------------------------------------------------------------------------

## Generate a standard array assignment. Returns the 6 values to assign.
func get_standard_array() -> Array[int]:
	return STANDARD_ARRAY.duplicate()


## Roll 4d6 drop lowest for one ability score.
func roll_one_stat() -> int:
	var rolls: Array[int] = []
	for i in 4:
		rolls.append(randi_range(1, 6))
	rolls.sort()
	# Drop lowest (index 0).
	return rolls[1] + rolls[2] + rolls[3]


## Roll a full set of 6 ability scores (4d6 drop lowest each).
func roll_all_stats() -> Array[int]:
	var results: Array[int] = []
	for i in 6:
		results.append(roll_one_stat())
	return results


## Calculate the point buy cost for a given set of scores.
func calculate_point_buy_cost(scores: AbilityScores) -> int:
	var total: int = 0
	for ability in AbilityScores.ABILITIES:
		var s: int = scores.get_score(ability)
		var cost: int = POINT_BUY_COSTS.get(s, -1)
		if cost < 0:
			return -1  # Invalid score for point buy.
		total += cost
	return total


## Returns true if the point buy scores are valid (total cost <= budget, scores in range).
func is_point_buy_valid(scores: AbilityScores) -> bool:
	var cost: int = calculate_point_buy_cost(scores)
	return cost >= 0 and cost <= POINT_BUY_BUDGET


# ---------------------------------------------------------------------------
# Skill helpers
# ---------------------------------------------------------------------------

## Returns the total number of skill proficiencies the character should pick.
func _get_total_skill_count() -> int:
	var count: int = 0
	if chosen_class != null:
		count += chosen_class.num_skill_choices
	# Background skills are granted automatically (not chosen from class list).
	return count


## Returns the skills granted automatically by the background.
func get_background_skills() -> Array[StringName]:
	if chosen_background == null:
		return [] as Array[StringName]
	return chosen_background.skill_proficiencies.duplicate()


## Returns the skills available for class selection (excluding background grants).
func get_available_class_skills() -> Array[StringName]:
	if chosen_class == null:
		return [] as Array[StringName]
	var bg_skills: Array[StringName] = get_background_skills()
	var available: Array[StringName] = []
	for skill in chosen_class.skill_choices:
		if skill not in bg_skills:
			available.append(skill)
	return available


## Returns how many class skills the player still needs to choose.
func get_remaining_class_skill_picks() -> int:
	if chosen_class == null:
		return 0
	return chosen_class.num_skill_choices - chosen_skills.size()


# ---------------------------------------------------------------------------
# Equipment helpers
# ---------------------------------------------------------------------------

## Returns the default equipment ids for the chosen class.
func get_default_equipment() -> Array[StringName]:
	if chosen_class == null:
		return [] as Array[StringName]
	var key: String = String(chosen_class.id)
	var defaults: Array = DEFAULT_EQUIPMENT.get(key, [])
	var result: Array[StringName] = []
	for item_id in defaults:
		result.append(StringName(item_id))
	return result


# ---------------------------------------------------------------------------
# Finalize
# ---------------------------------------------------------------------------

## Assemble the complete CharacterData from all chosen options.
func finalize() -> CharacterData:
	if not is_complete():
		push_error("CharacterCreator: Cannot finalize — creation is not complete.")
		return null

	var character := CharacterData.new()

	# Identity.
	character.character_name = character_name
	character.level = 1
	character.experience_points = 0

	# Sub-resources.
	character.character_class = chosen_class
	character.species = chosen_species
	character.background = chosen_background

	# Ability scores — copy and apply background bonuses.
	var scores := AbilityScores.new()
	for ability in AbilityScores.ABILITIES:
		scores.set_score(ability, ability_scores.get_score(ability))
	# Apply background ability score increases.
	if chosen_background.ability_score_increases.size() > 0:
		for ability_key in chosen_background.ability_score_increases:
			var bonus: int = int(chosen_background.ability_score_increases[ability_key])
			var current: int = scores.get_score(StringName(ability_key))
			scores.set_score(StringName(ability_key), mini(current + bonus, 20))
	character.ability_scores = scores

	# HP: hit die max + CON modifier at level 1.
	var con_mod: int = scores.get_modifier(&"constitution")
	character.max_hp = chosen_class.hit_die + con_mod
	if character.max_hp < 1:
		character.max_hp = 1
	character.current_hp = character.max_hp
	character.hit_dice_remaining = 1

	# Speed from species.
	character.speed = chosen_species.base_speed

	# Skill proficiencies: background + class choices.
	var all_skills: Array[StringName] = []
	for skill in get_background_skills():
		if skill not in all_skills:
			all_skills.append(skill)
	for skill in chosen_skills:
		if skill not in all_skills:
			all_skills.append(skill)
	character.skill_proficiencies = all_skills

	# Languages from species.
	character.languages = chosen_species.languages.duplicate()

	# Equipment — use chosen or defaults.
	var equip_ids: Array[StringName] = chosen_equipment_ids
	if equip_ids.is_empty():
		equip_ids = get_default_equipment()

	var equipped_weapons_arr: Array[Resource] = []
	for item_id in equip_ids:
		var item: Resource = DataRegistry.get_item(item_id)
		if item == null:
			continue
		if item is ArmorData:
			var armor_item: ArmorData = item as ArmorData
			if armor_item.armor_category == &"shield":
				character.equipped_shield = armor_item
			else:
				character.equipped_armor = armor_item
		elif item is WeaponData:
			equipped_weapons_arr.append(item)
		# Also add to inventory.
		character.inventory.append(item)
	character.equipped_weapons = equipped_weapons_arr

	# AC calculation.
	character.armor_class = RulesEngine.calculate_ac(character)

	# Initiative.
	character.initiative_bonus = 0

	# Spellcasting setup for casters.
	if chosen_class.is_spellcaster:
		var progression: LevelProgression = DataRegistry.get_level_progression(chosen_class.id)
		if progression != null:
			var slots: Array[int] = progression.get_spell_slots(1)
			character.max_spell_slots = slots.duplicate()
			character.spell_slots = slots.duplicate()

	# Starting gold from background.
	character.gold = chosen_background.starting_gold

	# Apply origin feat from background.
	if chosen_background.origin_feat != &"":
		var feat: FeatData = DataRegistry.get_feat(chosen_background.origin_feat)
		if feat != null:
			character.feats.append(feat)

	return character

class_name MonsterData
extends Resource

## Full stat block for a monster or NPC, following the 5e stat block format.
## Covers ability scores, actions, traits, legendary/lair actions, and spellcasting.

## Unique identifier for this monster.
@export var id: StringName

## Human-readable name.
@export var display_name: String

## Flavor text or lore description.
@export_multiline var description: String

## Creature size: "tiny", "small", "medium", "large", "huge", "gargantuan".
@export var size: StringName = &"medium"

## Creature type: "aberration", "beast", "celestial", "construct", "dragon",
## "elemental", "fey", "fiend", "giant", "humanoid", "monstrosity", "ooze",
## "plant", "undead".
@export var creature_type: StringName = &"beast"

## Alignment string (e.g., "chaotic evil", "lawful good", "unaligned").
@export var alignment: String = "unaligned"

## Base armor class.
@export var armor_class: int = 10

## Description of AC source (e.g., "natural armor", "chain mail").
@export var ac_description: String

## Maximum hit points.
@export var hit_points: int = 10

## Hit dice expression (e.g., "2d8", "10d10+30").
@export var hit_dice: String = "2d8"

## Movement speeds in feet. Keys: "walk", "fly", "swim", "climb", "burrow".
@export var speed: Dictionary = {"walk": 30}

## Reference to an AbilityScores resource holding STR, DEX, CON, INT, WIS, CHA.
@export var ability_scores: Resource

## Saving throw bonuses keyed by ability name (e.g., {"dexterity": 4, "wisdom": 3}).
@export var saving_throws: Dictionary

## Skill check bonuses keyed by skill name (e.g., {"perception": 3, "stealth": 5}).
@export var skills: Dictionary

## Damage types this creature takes double damage from.
@export var damage_vulnerabilities: Array[StringName]

## Damage types this creature takes half damage from.
@export var damage_resistances: Array[StringName]

## Damage types this creature is immune to.
@export var damage_immunities: Array[StringName]

## Conditions this creature is immune to.
@export var condition_immunities: Array[StringName]

## Senses and their ranges (e.g., {"darkvision": 60, "passive_perception": 12}).
@export var senses: Dictionary

## Languages this creature can speak or understand.
@export var languages: Array[StringName]

## Challenge rating (e.g., 0.25 for CR 1/4, 0.5 for CR 1/2, 1.0 for CR 1).
@export var challenge_rating: float = 0.0

## Experience points awarded for defeating this creature.
@export var xp_reward: int = 0

## Proficiency bonus derived from challenge rating.
@export var proficiency_bonus: int = 2

## Special traits (e.g., Pack Tactics, Keen Senses). Each entry has "name" and "description".
@export var traits: Array[Dictionary]

## Standard actions. Each entry has "name", "description", and optionally
## "attack_bonus", "damage", "reach", "range", etc.
@export var actions: Array[Dictionary]

## Bonus actions available to this creature.
@export var bonus_actions: Array[Dictionary]

## Reactions available to this creature.
@export var reactions: Array[Dictionary]

## Legendary actions. Each entry has "name", "description", and optionally "cost".
@export var legendary_actions: Array[Dictionary]

## Number of legendary actions available per round (typically 3).
@export var legendary_action_count: int = 0

## Lair actions triggered on initiative count 20.
@export var lair_actions: Array[Dictionary]

## Spellcasting information: {"ability": "wisdom", "dc": 13, "attack_bonus": 5,
## "spells": {"0": ["light", "sacred_flame"], "1": ["bless", "cure_wounds"]}}.
@export var spellcasting: Dictionary


## Returns the ability modifier for the given ability by delegating to the
## ability_scores resource. Returns 0 if ability_scores is not set.
func get_modifier(ability: StringName) -> int:
	if ability_scores == null:
		return 0
	if ability_scores.has_method("get_modifier"):
		return ability_scores.get_modifier(ability)
	return 0

class_name BackgroundData
extends Resource

## Resource defining a character background (e.g., Soldier, Sage, Acolyte).
## Backgrounds provide skill proficiencies, equipment, and in the 2024 rules,
## an origin feat and ability score increases.

## Unique identifier for this background (e.g., "soldier", "sage").
@export var id: StringName
## Human-readable name for display (e.g., "Soldier").
@export var display_name: String
## Full text description of the background.
@export_multiline var description: String

## Skill proficiencies granted by this background.
@export var skill_proficiencies: Array[StringName]
## Tool proficiencies granted by this background.
@export var tool_proficiencies: Array[StringName]
## Number of additional languages the character can choose.
@export var languages_count: int = 0

## Text descriptions of starting equipment provided by this background.
@export var starting_equipment: Array[String]
## Starting gold pieces.
@export var starting_gold: int = 0

## The id of the feat granted by this background (2024 rules background feat).
@export var feat_id: StringName
## Ability score increases as a dictionary mapping ability name to bonus value.
## Example: {"strength": 2, "constitution": 1, "wisdom": 1}
@export var ability_score_increases: Dictionary
## The id of the origin feat granted by this background (2024 rules).
@export var origin_feat: StringName

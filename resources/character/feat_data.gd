class_name FeatData
extends Resource

## Resource defining a feat that characters can acquire.
## Feats are categorized as general, origin, fighting style, or epic boon.

## Unique identifier for this feat (e.g., "great_weapon_master", "lucky").
@export var id: StringName
## Human-readable name for display (e.g., "Great Weapon Master").
@export var display_name: String
## Full text description of the feat.
@export_multiline var description: String

## The feat category: "general", "origin", "fighting_style", or "epic_boon".
@export var category: StringName
## Minimum character level required to take this feat.
@export var level_prerequisite: int = 1
## Ability score prerequisites. Maps ability name to minimum required score.
## Example: {"strength": 13} means Strength must be 13 or higher.
@export var ability_prerequisite: Dictionary
## Whether this feat can be taken more than once.
@export var repeatable: bool = false

## Structured effect data for the feat.
## Each entry is a Dictionary with keys: "type" (String), "value" (Variant),
## and any additional keys relevant to the effect type.
## Example: {"type": "ability_score_increase", "value": 1, "choices": ["strength", "dexterity"]}
@export var effects: Array[Dictionary]

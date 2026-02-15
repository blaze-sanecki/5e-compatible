class_name QuestObjective
extends Resource

## A single objective within a quest, tracking progress toward a specific goal.
## Supports kill, collect, talk, reach, and custom objective types.

## Unique identifier for this objective within its quest.
@export var id: StringName

## Human-readable description shown in the quest journal (e.g., "Defeat 5 goblins").
@export var description: String

## The type of objective: "kill", "collect", "talk", "reach", "custom".
@export var objective_type: StringName = &"custom"

## Identifier of the target entity, item, NPC, or location this objective tracks.
@export var target_id: StringName

## Number of times the target must be interacted with to complete the objective.
@export var required_count: int = 1

## Current progress toward the required count.
@export var current_count: int = 0

## Whether this objective is optional (not required for quest completion).
@export var is_optional: bool = false


## Returns true if the objective has been fulfilled (current_count >= required_count).
func is_complete() -> bool:
	return current_count >= required_count

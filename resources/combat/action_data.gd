class_name ActionData
extends Resource

## Describes a generic action a creature can take during combat.
## Used as a base for attacks, special abilities, and other combat options.

## Unique identifier for this action.
@export var id: StringName

## Human-readable name shown in the UI.
@export var display_name: String

## Full text description of what this action does.
@export var description: String

## The type of action economy this consumes: "action", "bonus_action", "reaction", "free".
@export var action_type: StringName = &"action"

## Whether this is melee, ranged, self-targeted, or touch: "melee", "ranged", "self", "touch".
@export var range_type: StringName = &"melee"

## Range in feet. Typically 5 for melee, higher for ranged.
@export var range_ft: int = 5

## Whether this action requires selecting a target.
@export var requires_target: bool = true

## Maximum number of targets this action can affect.
@export var max_targets: int = 1

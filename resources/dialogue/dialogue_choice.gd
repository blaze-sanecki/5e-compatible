class_name DialogueChoice
extends Resource

## Represents one selectable choice within a dialogue node.
## Supports conditions for availability, visibility, and triggered events.

## The text displayed to the player for this choice.
@export var text: String

## The node_id to navigate to when this choice is selected.
@export var next_node_id: StringName

## Conditions that must be met to select this choice.
## Each Dictionary describes one condition, e.g.,
## {"type": "skill_check", "skill": "persuasion", "dc": 15} or
## {"type": "has_item", "item_id": "golden_key"}.
@export var conditions: Array[Dictionary]

## Conditions that must be met for this choice to appear at all.
## Uses the same format as conditions. If any fail, the choice is hidden.
@export var visible_conditions: Array[Dictionary]

## Events triggered when this choice is selected.
## Each Dictionary describes one event, e.g.,
## {"type": "set_flag", "flag": "agreed_to_help", "value": true}.
@export var events: Array[Dictionary]

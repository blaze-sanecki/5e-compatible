class_name DialogueChoice
extends Resource

## Represents one selectable choice within a dialogue node.
## Supports conditions for availability, visibility, and triggered events.

## The text displayed to the player for this choice.
@export var text: String

## The node_id to navigate to when this choice is selected.
@export var next_node_id: StringName

## Conditions that must be met to select this choice.
@export var conditions: Array[DialogueCondition]

## Conditions that must be met for this choice to appear at all.
## If any fail, the choice is hidden.
@export var visible_conditions: Array[DialogueCondition]

## Events triggered when this choice is selected.
@export var events: Array[DialogueEvent]

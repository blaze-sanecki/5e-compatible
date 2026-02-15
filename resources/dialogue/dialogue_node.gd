class_name DialogueNode
extends Resource

## A single node within a dialogue tree, representing one block of spoken text.
## Can branch into multiple choices or auto-advance to the next node.

## Unique identifier for this node within its dialogue tree.
@export var node_id: StringName

## Name of the character speaking this line.
@export var speaker: String

## The dialogue text displayed to the player.
@export_multiline var text: String

## Available player choices branching from this node.
## Each entry should be a DialogueChoice resource.
@export var choices: Array[Resource]

## If true, the conversation ends after this node (no choices or next node).
@export var is_end: bool = false

## The node_id to auto-advance to when there are no choices.
## Ignored if choices are present or is_end is true.
@export var next_node_id: StringName

## Events triggered when this node is displayed.
@export var events: Array[DialogueEvent]

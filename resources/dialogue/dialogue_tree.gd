class_name DialogueTree
extends Resource

## Top-level container for a branching dialogue conversation.
## References an array of DialogueNode resources and designates a starting node.

## Unique identifier for this dialogue tree.
@export var id: StringName

## Name of the NPC this dialogue belongs to.
@export var npc_name: String

## All dialogue nodes that make up this conversation.
@export var nodes: Array[Resource]

## The node_id of the first node to display when the conversation starts.
@export var start_node_id: StringName


## Finds and returns the DialogueNode with the matching node_id.
## Returns null if no node with that id exists.
func get_node_by_id(node_id: StringName) -> Resource:
	for node in nodes:
		if node != null and node.get(&"node_id") == node_id:
			return node
	return null

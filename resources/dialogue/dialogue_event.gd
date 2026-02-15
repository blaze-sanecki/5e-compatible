class_name DialogueEvent
extends Resource

## An event triggered during dialogue (give item, start quest, set flag).

## "give_item", "start_quest", "set_flag".
@export var type: StringName = &""
@export var item_id: StringName = &""
@export var quantity: int = 1
@export var quest_id: StringName = &""
@export var flag: String
@export var value: bool = true

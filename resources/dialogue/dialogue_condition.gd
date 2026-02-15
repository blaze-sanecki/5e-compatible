class_name DialogueCondition
extends Resource

## A condition that gates a dialogue choice (skill check, item check, flag check).

## "skill_check", "has_item", "quest_complete", "not_flag".
@export var type: StringName = &""
@export var skill: StringName = &""
@export var dc: int = 10
@export var fail_node_id: StringName = &""
@export var item_id: StringName = &""
@export var quest_id: StringName = &""
@export var flag: String

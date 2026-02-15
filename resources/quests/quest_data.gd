class_name QuestData
extends Resource

## Defines a quest with objectives, rewards, and prerequisite tracking.
## Supports both main story quests and optional side quests.

## Unique identifier for this quest.
@export var id: StringName

## Human-readable quest name shown in the journal.
@export var display_name: String

## Full description of the quest, including context and goals.
@export_multiline var description: String

## Ordered list of objectives that must be completed.
## Each entry should be a QuestObjective resource.
@export var objectives: Array[Resource]

## Experience points awarded upon quest completion.
@export var rewards_xp: int = 0

## Gold pieces awarded upon quest completion.
@export var rewards_gold: int = 0

## Item resources awarded upon quest completion.
@export var rewards_items: Array[Resource]

## Quest ids that must be completed before this quest becomes available.
@export var prerequisite_quests: Array[StringName]

## Whether this quest is part of the main storyline.
@export var is_main_quest: bool = false

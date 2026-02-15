class_name ConditionData
extends Resource

## Defines a condition that can be applied to a creature (e.g., blinded, poisoned).
## Conditions impose mechanical effects and may end under specific circumstances.

## Unique identifier for this condition.
@export var id: StringName

## Human-readable name shown in the UI.
@export var display_name: String

## Full text description of the condition and its effects.
@export var description: String

## Structured mechanical effects this condition imposes.
## Each entry is a Dictionary such as {"type": "disadvantage", "on": "attack_rolls"}
## or {"type": "speed", "value": 0} for conditions like grappled/restrained.
@export var effects: Array[Dictionary]

## When the condition can end: "end_of_turn", "start_of_turn", "save", "never", "custom".
@export var ends_on: StringName

## The ability used for a saving throw to end the condition (if ends_on == "save").
@export var save_ability: StringName

## The DC of the saving throw to end the condition (if ends_on == "save").
@export var save_dc: int = 0

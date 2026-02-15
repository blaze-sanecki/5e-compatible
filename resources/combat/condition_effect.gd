class_name ConditionEffect
extends Resource

## A single mechanical effect imposed by a condition.

## Effect type: "auto_fail", "advantage", "disadvantage", "cant_attack",
## "cant_approach", "speed", "incapacitated", "unseen", "auto_crit",
## "resistance", "immunity", "movement_cost", "prone".
@export var type: StringName = &""

## What this effect applies to (e.g., "attack_rolls", "ability_checks").
@export var on: StringName = &""

## Numeric value for speed, movement_cost, etc.
@export var value: int = 0

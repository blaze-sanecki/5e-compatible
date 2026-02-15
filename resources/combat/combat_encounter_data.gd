class_name CombatEncounterData
extends Resource

## Defines a combat encounter: which monsters spawn, where, and rewards.

## Unique identifier for this encounter.
@export var id: StringName

## Human-readable name.
@export var display_name: String

## Monster spawn entries for this encounter.
@export var monster_spawns: Array[MonsterSpawnEntry]

## Encounter difficulty: "easy", "medium", "hard", "deadly".
@export var difficulty: StringName = &"medium"

## Whether this encounter grants XP on completion.
@export var grants_xp: bool = true

## Whether the encounter can repeat (e.g., random encounters).
@export var repeatable: bool = false

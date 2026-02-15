class_name MonsterSpawnEntry
extends Resource

## A single monster spawn point within a combat encounter.

@export var monster_id: StringName = &""
@export var cell: Vector2i = Vector2i.ZERO
@export var count: int = 1

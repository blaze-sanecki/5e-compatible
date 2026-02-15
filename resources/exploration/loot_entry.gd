class_name LootEntry
extends Resource

## A single entry in a loot table (chests, enemy drops).

@export var item_id: StringName = &""
@export var quantity: int = 1
@export var chance: float = 1.0  ## 0.0–1.0 drop probability.

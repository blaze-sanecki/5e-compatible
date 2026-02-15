class_name InteractableData
extends Resource

## Defines properties for a dungeon interactable object (door, chest, lever).

enum InteractableType { DOOR, CHEST, LEVER, TRAP, OTHER }

## Unique identifier.
@export var id: StringName

## Display name.
@export var display_name: String

## The type of interactable.
@export var type: InteractableType = InteractableType.OTHER

## Whether this object is currently locked.
@export var is_locked: bool = false

## DC for Thieves' Tools check to unlock.
@export var lock_dc: int = 15

## Key item ID that can bypass the lock.
@export var key_item_id: StringName = &""

## Loot table entries.
@export var loot_table: Array[LootEntry] = []

## Whether this interactable has been used/opened.
@export var is_used: bool = false

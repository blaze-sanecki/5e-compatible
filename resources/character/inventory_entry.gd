class_name InventoryEntry
extends Resource

## Wraps an item with a quantity for inventory tracking.
## Allows stackable items like arrows or potions to occupy a single slot.

## The item this entry refers to (ItemData or any subclass).
@export var item: Resource

## How many of this item the character has.
@export var quantity: int = 1

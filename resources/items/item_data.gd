class_name ItemData
extends Resource

## Base resource for all items in the game.
## Weapons, armor, and magic items extend this with additional fields.

## Unique identifier for this item.
@export var id: StringName

## Human-readable name shown in the UI and inventory.
@export var display_name: String

## Full text description of the item.
@export var description: String

## Weight of the item in pounds.
@export var weight: float = 0.0

## Base cost of the item in gold pieces.
@export var cost_gp: float = 0.0

## Whether multiple items can occupy the same inventory slot.
@export var stackable: bool = false

## Maximum number of items in a single stack (only relevant if stackable is true).
@export var max_stack: int = 1

## The category of item: "weapon", "armor", "gear", "tool", "consumable", "treasure".
@export var item_type: StringName = &"gear"

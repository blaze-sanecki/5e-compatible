class_name MagicItemData
extends ItemData

## Extends ItemData with properties specific to magic items, including rarity,
## attunement, charges, and magical effects.

## Rarity tier: "common", "uncommon", "rare", "very_rare", "legendary", "artifact".
@export var rarity: StringName = &"common"

## Whether the item requires attunement to use its magical properties.
@export var requires_attunement: bool = false

## Description of attunement prerequisites (e.g., "by a cleric or paladin").
@export var attunement_requirements: String

## Generic magic bonus applied by this item (e.g., +1, +2, +3 for weapons/armor).
@export var magic_bonus: int = 0

## Current number of charges remaining.
@export var charges: int = 0

## Maximum number of charges this item can hold.
@export var max_charges: int = 0

## When and how charges are restored (e.g., "dawn", "dusk", "never").
@export var recharge: String

## Array of magical effects this item grants. Each Dictionary describes one effect,
## e.g., {"type": "bonus_ac", "value": 1} or {"type": "cast_spell", "spell_id": "fireball"}.
@export var effects: Array[Dictionary]

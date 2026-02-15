class_name WeaponData
extends ItemData

## Extends ItemData with weapon-specific properties including damage, range,
## weapon properties (finesse, heavy, etc.), and 2024 weapon mastery.

## Weapon category: "simple" or "martial".
@export var weapon_category: StringName = &"simple"

## Primary damage roll for this weapon.
@export var damage: DamageRoll

## Alternate damage roll when wielded with two hands (for versatile weapons).
## Leave null for non-versatile weapons.
@export var versatile_damage: DamageRoll

## Weapon properties such as "finesse", "heavy", "light", "loading", "reach",
## "thrown", "two_handed", "versatile", "ammunition", "special".
@export var properties: Array[StringName]

## Normal range in feet. 5 for standard melee weapons.
@export var range_normal: int = 5

## Long range in feet. 0 means the weapon has no long range (most melee weapons).
@export var range_long: int = 0

## Weapon mastery property from the 2024 rules (e.g., "cleave", "graze", "nick").
@export var mastery_property: StringName


func _init() -> void:
	item_type = &"weapon"


## Returns true if this weapon can be used in melee (range_normal <= 10 or has no
## ranged-only indicator). Thrown weapons count as both melee and ranged.
func is_melee() -> bool:
	return range_normal <= 10


## Returns true if this weapon can be used at range (has a long range value,
## the ammunition property, or the thrown property).
func is_ranged() -> bool:
	return range_long > 0 or has_property(&"ammunition") or has_property(&"thrown")


## Returns true if this weapon has the given property.
func has_property(prop: StringName) -> bool:
	return properties.has(prop)

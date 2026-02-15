class_name ArmorData
extends ItemData

## Extends ItemData with armor-specific properties such as AC calculation,
## Dexterity caps, strength requirements, and stealth penalties.

## Armor category: "light", "medium", "heavy", "shield".
@export var armor_category: StringName = &"light"

## Base armor class provided by this armor.
@export var base_ac: int = 11

## Whether the wearer adds their Dexterity modifier to AC.
@export var add_dex: bool = true

## Maximum Dexterity bonus that can be added to AC. -1 means unlimited.
@export var max_dex_bonus: int = -1

## Minimum Strength score required to wear this armor without penalty.
@export var strength_requirement: int = 0

## Whether wearing this armor imposes disadvantage on Stealth checks.
@export var stealth_disadvantage: bool = false


func _init() -> void:
	item_type = &"armor"


## Calculates the effective AC for a given Dexterity modifier.
## Accounts for whether Dex is added and any maximum Dex bonus cap.
func calculate_ac(dex_modifier: int) -> int:
	if not add_dex:
		return base_ac

	var dex_bonus: int = dex_modifier
	if max_dex_bonus >= 0:
		dex_bonus = mini(dex_bonus, max_dex_bonus)

	return base_ac + dex_bonus

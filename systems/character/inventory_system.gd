class_name InventorySystem
extends RefCounted

## Static utility methods for inventory management.
## Handles adding/removing items, equipping gear, and weight calculations.


## Add an item to a character's inventory. Stacks if possible.
static func add_item(character: CharacterData, item: Resource, quantity: int = 1) -> void:
	# Check for existing stackable entry.
	if item is ItemData and item.stackable:
		for entry in character.inventory:
			if entry is InventoryEntry and entry.item == item:
				entry.quantity += quantity
				EventBus.item_acquired.emit(character, item)
				return

		# Create a new InventoryEntry for stackable items.
		var entry := InventoryEntry.new()
		entry.item = item
		entry.quantity = quantity
		character.inventory.append(entry)
	else:
		# Non-stackable: add directly (one per slot).
		for i in quantity:
			character.inventory.append(item)
	EventBus.item_acquired.emit(character, item)


## Remove an item from inventory. Returns true if successful.
static func remove_item(character: CharacterData, item: Resource, quantity: int = 1) -> bool:
	for i in character.inventory.size():
		var entry: Resource = character.inventory[i]
		if entry is InventoryEntry and entry.item == item:
			entry.quantity -= quantity
			if entry.quantity <= 0:
				character.inventory.remove_at(i)
			return true
		elif entry == item:
			character.inventory.remove_at(i)
			return true
	return false


## Equip a weapon from inventory.
static func equip_weapon(character: CharacterData, weapon: WeaponData) -> void:
	if weapon not in character.inventory:
		return
	character.equipped_weapons.append(weapon)
	EventBus.item_equipped.emit(character, weapon)


## Unequip a weapon.
static func unequip_weapon(character: CharacterData, weapon: WeaponData) -> void:
	var idx: int = character.equipped_weapons.find(weapon)
	if idx >= 0:
		character.equipped_weapons.remove_at(idx)
		EventBus.item_unequipped.emit(character, weapon)


## Equip armor (replaces current armor). Recalculates AC.
static func equip_armor(character: CharacterData, armor: ArmorData) -> void:
	if armor not in character.inventory:
		return
	if character.equipped_armor != null:
		EventBus.item_unequipped.emit(character, character.equipped_armor)
	character.equipped_armor = armor
	character.armor_class = RulesEngine.calculate_ac(character)
	EventBus.item_equipped.emit(character, armor)


## Unequip armor. Recalculates AC.
static func unequip_armor(character: CharacterData) -> void:
	if character.equipped_armor == null:
		return
	var old_armor: Resource = character.equipped_armor
	character.equipped_armor = null
	character.armor_class = RulesEngine.calculate_ac(character)
	EventBus.item_unequipped.emit(character, old_armor)


## Equip a shield. Recalculates AC.
static func equip_shield(character: CharacterData, shield: ArmorData) -> void:
	if shield not in character.inventory:
		return
	if character.equipped_shield != null:
		EventBus.item_unequipped.emit(character, character.equipped_shield)
	character.equipped_shield = shield
	character.armor_class = RulesEngine.calculate_ac(character)
	EventBus.item_equipped.emit(character, shield)


## Unequip shield. Recalculates AC.
static func unequip_shield(character: CharacterData) -> void:
	if character.equipped_shield == null:
		return
	var old_shield: Resource = character.equipped_shield
	character.equipped_shield = null
	character.armor_class = RulesEngine.calculate_ac(character)
	EventBus.item_unequipped.emit(character, old_shield)


## Use a consumable item. Applies effects, removes one from inventory.
## Returns a result dictionary with details of what happened.
static func use_item(character: CharacterData, item: ItemData) -> Dictionary:
	if item.item_type != &"consumable":
		return {"success": false, "message": "Not a consumable item."}

	if item.effects.is_empty():
		return {"success": false, "message": "Item has no effects."}

	# Check the character actually has the item.
	var found: bool = false
	for entry in character.inventory:
		if entry is InventoryEntry and entry.item == item:
			found = true
			break
		elif entry == item:
			found = true
			break
	if not found:
		return {"success": false, "message": "Item not in inventory."}

	var results: Array[Dictionary] = []

	for effect in item.effects:
		var effect_type: String = str(effect.get("type", ""))
		match effect_type:
			"heal":
				var dice_str: String = str(effect.get("dice", "1d4"))
				var roll_result = DiceRoller.roll(dice_str)
				var heal_amount: int = maxi(roll_result.total, 1)
				character.current_hp = mini(character.current_hp + heal_amount, character.max_hp)
				EventBus.character_healed.emit(character, heal_amount)
				results.append({"type": "heal", "amount": heal_amount, "dice": dice_str})
			"remove_condition":
				var condition_name: StringName = StringName(str(effect.get("condition", "")))
				if condition_name in character.conditions:
					character.conditions.erase(condition_name)
					EventBus.condition_removed.emit(character, condition_name)
					results.append({"type": "remove_condition", "condition": condition_name})

	# Consume one from inventory.
	remove_item(character, item, 1)

	EventBus.item_used.emit(character, item)

	return {"success": true, "item_name": item.display_name, "effects": results}


## Calculate total weight of all inventory items.
static func get_total_weight(character: CharacterData) -> float:
	var total: float = 0.0
	for entry in character.inventory:
		if entry is InventoryEntry:
			if entry.item is ItemData:
				total += entry.item.weight * entry.quantity
		elif entry is ItemData:
			total += entry.weight
	# Add equipped items if not already in inventory.
	if character.equipped_armor != null and character.equipped_armor not in character.inventory:
		total += character.equipped_armor.weight
	if character.equipped_shield != null and character.equipped_shield not in character.inventory:
		total += character.equipped_shield.weight
	return total


## Add gold to the character.
static func add_gold(character: CharacterData, amount: int) -> void:
	character.gold += amount
	EventBus.gold_changed.emit(character, character.gold)


## Remove gold from the character. Returns true if sufficient funds.
static func remove_gold(character: CharacterData, amount: int) -> bool:
	if character.gold < amount:
		return false
	character.gold -= amount
	EventBus.gold_changed.emit(character, character.gold)
	return true

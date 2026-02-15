class_name ChestInteractable
extends InteractableBase

## A chest that generates loot and adds items to the party inventory.
##
## Uses the loot_table from InteractableData. Each entry has an item_id,
## quantity, and chance. Items are added via InventorySystem.

## Whether the chest has already been looted (delegates to state).
var is_looted: bool:
	get: return state.is_looted
	set(v): state.is_looted = v


func _perform_interaction() -> void:
	if is_looted:
		print("Chest is already empty.")
		return

	state.set_looted()
	_update_visual()

	if interactable_data:
		interactable_data.is_used = true

	var name_str: String = interactable_data.display_name if interactable_data else "Chest"
	print("%s opened!" % name_str)

	# Generate and distribute loot.
	_generate_loot()


## Apply visual state for the current looted status.
func _update_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.7) if is_looted else Color.WHITE


func _generate_loot() -> void:
	if interactable_data == null:
		return

	var character: Resource = PartyManager.get_active_character()

	for entry in interactable_data.loot_table:
		var item_id: StringName = entry.item_id
		var quantity: int = entry.quantity
		var chance: float = entry.chance

		if item_id == &"":
			continue

		# Roll for drop chance.
		if randf() > chance:
			continue

		# Handle gold separately.
		if item_id == &"gold":
			print("  Found %d gold!" % quantity)
			if character:
				InventorySystem.add_gold(character, quantity)
			continue

		# Look up the item in DataRegistry.
		var item: Resource = DataRegistry.get_item(item_id)
		if item == null:
			push_warning("ChestInteractable: Item '%s' not found in DataRegistry." % item_id)
			continue

		var item_name: String = item.display_name if item.get("display_name") else str(item_id)
		print("  Found %s (x%d)!" % [item_name, quantity])
		if character:
			InventorySystem.add_item(character, item, quantity)

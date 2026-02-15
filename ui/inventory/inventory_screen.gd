extends Control

## Full-screen inventory overlay.
## Left: Equipment slots. Right: Inventory list with item details.

var _character: CharacterData

@onready var armor_label: Label = %ArmorLabel
@onready var shield_label: Label = %ShieldLabel
@onready var weapons_label: Label = %WeaponsLabel
@onready var unequip_armor_btn: Button = %UnequipArmorBtn
@onready var unequip_shield_btn: Button = %UnequipShieldBtn
@onready var inventory_list: ItemList = %InventoryList
@onready var item_details: RichTextLabel = %ItemDetails
@onready var equip_btn: Button = %EquipBtn
@onready var drop_btn: Button = %DropBtn
@onready var gold_label: Label = %GoldLabel
@onready var weight_label: Label = %WeightLabel
@onready var close_btn: Button = %CloseBtn

var _inventory_items: Array = []  # Parallel array to ItemList indices.
var _selected_index: int = -1


func _ready() -> void:
	_character = PartyManager.get_active_character()
	if _character == null:
		push_error("InventoryScreen: No active character.")
		return

	close_btn.pressed.connect(_on_close)
	unequip_armor_btn.pressed.connect(_on_unequip_armor)
	unequip_shield_btn.pressed.connect(_on_unequip_shield)
	equip_btn.pressed.connect(_on_equip)
	drop_btn.pressed.connect(_on_drop)
	inventory_list.item_selected.connect(_on_item_selected)

	_refresh()


func _refresh() -> void:
	if _character == null:
		return

	# Equipment slots.
	armor_label.text = _character.equipped_armor.display_name if _character.equipped_armor != null else "None"
	shield_label.text = _character.equipped_shield.display_name if _character.equipped_shield != null else "None"
	unequip_armor_btn.visible = _character.equipped_armor != null
	unequip_shield_btn.visible = _character.equipped_shield != null

	var weapon_names: PackedStringArray = []
	for w in _character.equipped_weapons:
		weapon_names.append(w.display_name)
	weapons_label.text = ", ".join(weapon_names) if weapon_names.size() > 0 else "None"

	# Gold and weight.
	gold_label.text = "%d gp" % _character.gold
	weight_label.text = "%.1f lb" % InventorySystem.get_total_weight(_character)

	# Inventory list.
	inventory_list.clear()
	_inventory_items.clear()
	for entry in _character.inventory:
		var item: Resource = entry
		var item_name: String = ""
		if entry is InventoryEntry:
			item = entry.item
			item_name = "%s (x%d)" % [item.display_name, entry.quantity]
		elif entry is ItemData:
			item_name = entry.display_name
		else:
			continue
		inventory_list.add_item(item_name)
		_inventory_items.append(item)

	# Reset selection.
	_selected_index = -1
	item_details.text = "Select an item to view details."
	equip_btn.visible = false
	drop_btn.visible = false


func _on_item_selected(index: int) -> void:
	_selected_index = index
	if index < 0 or index >= _inventory_items.size():
		return

	var item: Resource = _inventory_items[index]
	var text := "[b]%s[/b]\n\n" % item.display_name

	if item is WeaponData:
		text += "Type: %s %s\n" % [String(item.weapon_category).capitalize(), "Weapon"]
		text += "Damage: %s %s\n" % [item.damage.to_notation(), String(item.damage.damage_type).capitalize()]
		if item.versatile_damage != null:
			text += "Versatile: %s\n" % item.versatile_damage.to_notation()
		if item.properties.size() > 0:
			var props: PackedStringArray = []
			for p in item.properties:
				props.append(String(p).capitalize().replace("_", " "))
			text += "Properties: %s\n" % ", ".join(props)
		text += "Range: %d" % item.range_normal
		if item.range_long > 0:
			text += " / %d" % item.range_long
		text += " ft.\n"
	elif item is ArmorData:
		text += "Type: %s Armor\n" % String(item.armor_category).capitalize()
		text += "AC: %d" % item.base_ac
		if item.add_dex:
			text += " + DEX"
			if item.max_dex_bonus >= 0:
				text += " (max %d)" % item.max_dex_bonus
		text += "\n"
		if item.strength_requirement > 0:
			text += "Requires: STR %d\n" % item.strength_requirement
		if item.stealth_disadvantage:
			text += "Stealth: Disadvantage\n"

	if item is ItemData:
		text += "Weight: %.1f lb\n" % item.weight
		text += "Cost: %.0f gp\n" % item.cost_gp

	if item.get("description") and item.description != "":
		text += "\n%s\n" % item.description

	item_details.text = text

	# Show equip/drop buttons based on item type.
	equip_btn.visible = item is WeaponData or item is ArmorData
	drop_btn.visible = true

	if item is WeaponData:
		equip_btn.text = "Equip Weapon"
	elif item is ArmorData:
		var armor_item: ArmorData = item as ArmorData
		equip_btn.text = "Equip Shield" if armor_item.armor_category == &"shield" else "Equip Armor"


func _on_equip() -> void:
	if _selected_index < 0 or _selected_index >= _inventory_items.size():
		return
	var item: Resource = _inventory_items[_selected_index]
	if item is WeaponData:
		InventorySystem.equip_weapon(_character, item)
	elif item is ArmorData:
		var armor_item: ArmorData = item as ArmorData
		if armor_item.armor_category == &"shield":
			InventorySystem.equip_shield(_character, armor_item)
		else:
			InventorySystem.equip_armor(_character, armor_item)
	_refresh()


func _on_drop() -> void:
	if _selected_index < 0 or _selected_index >= _inventory_items.size():
		return
	var item: Resource = _inventory_items[_selected_index]
	InventorySystem.remove_item(_character, item)
	_refresh()


func _on_unequip_armor() -> void:
	InventorySystem.unequip_armor(_character)
	_refresh()


func _on_unequip_shield() -> void:
	InventorySystem.unequip_shield(_character)
	_refresh()


func _on_close() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORING)
	queue_free()

class_name PartySerializer
extends RefCounted

## Serializes and deserializes party members (CharacterData) to/from
## JSON-compatible dictionaries for save files.


static func serialize(party: Array) -> Array:
	var result: Array = []
	for member in party:
		if member is CharacterData:
			result.append(_serialize_character(member as CharacterData))
	return result


static func deserialize(party_data: Array) -> void:
	PartyManager.party.clear()
	for char_dict in party_data:
		var c := CharacterData.new()

		# Scalar fields.
		c.character_name = str(char_dict.get("character_name", ""))
		c.player_name = str(char_dict.get("player_name", ""))
		c.alignment = str(char_dict.get("alignment", ""))
		c.notes = str(char_dict.get("notes", ""))
		c.level = int(char_dict.get("level", 1))
		c.experience_points = int(char_dict.get("experience_points", 0))
		c.max_hp = int(char_dict.get("max_hp", 10))
		c.current_hp = int(char_dict.get("current_hp", 10))
		c.temp_hp = int(char_dict.get("temp_hp", 0))
		c.armor_class = int(char_dict.get("armor_class", 10))
		c.initiative_bonus = int(char_dict.get("initiative_bonus", 0))
		c.speed = int(char_dict.get("speed", 30))
		c.hit_dice_remaining = int(char_dict.get("hit_dice_remaining", 1))
		c.death_save_successes = int(char_dict.get("death_save_successes", 0))
		c.death_save_failures = int(char_dict.get("death_save_failures", 0))
		c.gold = int(char_dict.get("gold", 0))

		# Ability scores.
		c.ability_scores = AbilityScores.new()
		var scores: Dictionary = char_dict.get("ability_scores", {})
		c.ability_scores.strength = int(scores.get("strength", 10))
		c.ability_scores.dexterity = int(scores.get("dexterity", 10))
		c.ability_scores.constitution = int(scores.get("constitution", 10))
		c.ability_scores.intelligence = int(scores.get("intelligence", 10))
		c.ability_scores.wisdom = int(scores.get("wisdom", 10))
		c.ability_scores.charisma = int(scores.get("charisma", 10))

		# Sub-resource references via DataRegistry.
		var class_id: String = str(char_dict.get("class_id", ""))
		if not class_id.is_empty():
			c.character_class = DataRegistry.get_class_data(StringName(class_id))

		var subclass_id: String = str(char_dict.get("subclass_id", ""))
		if not subclass_id.is_empty():
			c.subclass = DataRegistry.get_subclass(StringName(subclass_id))

		var species_id: String = str(char_dict.get("species_id", ""))
		if not species_id.is_empty():
			c.species = DataRegistry.get_species(StringName(species_id))

		var background_id: String = str(char_dict.get("background_id", ""))
		if not background_id.is_empty():
			c.background = DataRegistry.get_background(StringName(background_id))

		# Proficiencies, expertise, conditions, languages.
		c.skill_proficiencies = _strings_to_string_name_array(char_dict.get("skill_proficiencies", []))
		c.expertise = _strings_to_string_name_array(char_dict.get("expertise", []))
		c.conditions = _strings_to_string_name_array(char_dict.get("conditions", []))
		c.languages = _strings_to_string_name_array(char_dict.get("languages", []))

		# Feats.
		c.feats = []
		for feat_id in char_dict.get("feat_ids", []):
			var feat: FeatData = DataRegistry.get_feat(StringName(str(feat_id)))
			if feat:
				c.feats.append(feat)

		# Inventory.
		c.inventory = []
		for inv_entry in char_dict.get("inventory", []):
			var item_id: String = str(inv_entry.get("id", ""))
			var qty: int = int(inv_entry.get("quantity", 1))
			var item: Resource = DataRegistry.get_item(StringName(item_id))
			if item:
				var entry := InventoryEntry.new()
				entry.item = item
				entry.quantity = qty
				c.inventory.append(entry)

		# Equipment.
		var armor_id: String = str(char_dict.get("equipped_armor_id", ""))
		if not armor_id.is_empty():
			c.equipped_armor = DataRegistry.get_armor(StringName(armor_id))

		var shield_id: String = str(char_dict.get("equipped_shield_id", ""))
		if not shield_id.is_empty():
			c.equipped_shield = DataRegistry.get_armor(StringName(shield_id))

		c.equipped_weapons = []
		for wid in char_dict.get("equipped_weapon_ids", []):
			var weapon: Resource = DataRegistry.get_weapon(StringName(str(wid)))
			if weapon:
				c.equipped_weapons.append(weapon)

		# Spell slots.
		var slots: Array = char_dict.get("spell_slots", [0, 0, 0, 0, 0, 0, 0, 0, 0])
		c.spell_slots = []
		for s in slots:
			c.spell_slots.append(int(s))
		var max_slots: Array = char_dict.get("max_spell_slots", [0, 0, 0, 0, 0, 0, 0, 0, 0])
		c.max_spell_slots = []
		for s in max_slots:
			c.max_spell_slots.append(int(s))

		# Spells — look up by id. Since we don't have a spell registry yet,
		# store as empty for now. The DataRegistry would need get_spell().
		c.prepared_spells = []
		c.known_spells = []
		c.known_cantrips = []
		c.concentration_spell = null

		PartyManager.party.append(c)

	PartyManager.party_changed.emit()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

static func _serialize_character(c: CharacterData) -> Dictionary:
	var data: Dictionary = {
		"character_name": c.character_name,
		"player_name": c.player_name,
		"alignment": c.alignment,
		"notes": c.notes,
		"level": c.level,
		"experience_points": c.experience_points,
		"max_hp": c.max_hp,
		"current_hp": c.current_hp,
		"temp_hp": c.temp_hp,
		"armor_class": c.armor_class,
		"initiative_bonus": c.initiative_bonus,
		"speed": c.speed,
		"hit_dice_remaining": c.hit_dice_remaining,
		"death_save_successes": c.death_save_successes,
		"death_save_failures": c.death_save_failures,
		"gold": c.gold,
	}

	# Ability scores.
	if c.ability_scores:
		data["ability_scores"] = {
			"strength": c.ability_scores.strength,
			"dexterity": c.ability_scores.dexterity,
			"constitution": c.ability_scores.constitution,
			"intelligence": c.ability_scores.intelligence,
			"wisdom": c.ability_scores.wisdom,
			"charisma": c.ability_scores.charisma,
		}

	# Sub-resource references by id.
	data["class_id"] = str(c.character_class.id) if c.character_class and c.character_class.get("id") else ""
	data["subclass_id"] = str(c.subclass.id) if c.subclass and c.subclass.get("id") else ""
	data["species_id"] = str(c.species.id) if c.species and c.species.get("id") else ""
	data["background_id"] = str(c.background.id) if c.background and c.background.get("id") else ""

	# Proficiencies and expertise as string arrays.
	data["skill_proficiencies"] = _string_name_array_to_strings(c.skill_proficiencies)
	data["expertise"] = _string_name_array_to_strings(c.expertise)
	data["conditions"] = _string_name_array_to_strings(c.conditions)
	data["languages"] = _string_name_array_to_strings(c.languages)

	# Feats by id.
	var feat_ids: Array = []
	for feat in c.feats:
		if feat and feat.get("id"):
			feat_ids.append(str(feat.id))
	data["feat_ids"] = feat_ids

	# Inventory as {id, quantity} pairs.
	var inv: Array = []
	for entry in c.inventory:
		if entry is InventoryEntry and entry.item and entry.item.get("id"):
			inv.append({"id": str(entry.item.id), "quantity": entry.quantity})
		elif entry is Resource and entry.get("id"):
			inv.append({"id": str(entry.id), "quantity": 1})
	data["inventory"] = inv

	# Equipment by id.
	data["equipped_armor_id"] = str(c.equipped_armor.id) if c.equipped_armor and c.equipped_armor.get("id") else ""
	data["equipped_shield_id"] = str(c.equipped_shield.id) if c.equipped_shield and c.equipped_shield.get("id") else ""
	var weapon_ids: Array = []
	for w in c.equipped_weapons:
		if w and w.get("id"):
			weapon_ids.append(str(w.id))
	data["equipped_weapon_ids"] = weapon_ids

	# Spell slots.
	data["spell_slots"] = c.spell_slots.duplicate()
	data["max_spell_slots"] = c.max_spell_slots.duplicate()

	# Spells by id.
	data["prepared_spell_ids"] = _resource_ids(c.prepared_spells)
	data["known_spell_ids"] = _resource_ids(c.known_spells)
	data["known_cantrip_ids"] = _resource_ids(c.known_cantrips)
	data["concentration_spell_id"] = str(c.concentration_spell.id) if c.concentration_spell and c.concentration_spell.get("id") else ""

	return data


static func _string_name_array_to_strings(arr: Array) -> Array:
	var result: Array = []
	for item in arr:
		result.append(str(item))
	return result


static func _strings_to_string_name_array(arr: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for item in arr:
		result.append(StringName(str(item)))
	return result


static func _resource_ids(arr: Array) -> Array:
	var result: Array = []
	for res in arr:
		if res and res.get("id"):
			result.append(str(res.id))
	return result

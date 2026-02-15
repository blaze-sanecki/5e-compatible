class_name LockCheck
extends RefCounted

## Shared lock-checking utility for interactables and portals.
##
## Checks key items first, then attempts a Thieves' Tools ability check.
## Mutates is_locked on the data resource when successful.


## Attempt to unlock a locked object.
## [param data] must have is_locked (bool), lock_dc (int). May have key_item_id (StringName).
## Returns true if unlocked (or was already unlocked).
static func try_unlock(data: Resource) -> bool:
	if data == null or not data.get("is_locked"):
		return true

	var character: Resource = PartyManager.get_active_character()
	if character == null:
		return false

	# Check if party has the key item.
	var key_id: StringName = data.get("key_item_id") if data.get("key_item_id") != null else &""
	if key_id != &"":
		for entry in character.inventory:
			var item: Resource = entry.get("item") if entry is Dictionary else entry
			if item and item.get("id") == key_id:
				data.is_locked = false
				return true

	# Attempt Thieves' Tools check (DEX + proficiency if applicable).
	var dex_mod: int = character.get_modifier(&"dexterity")
	var prof_bonus: int = 0
	if character.get("skill_proficiencies") != null:
		if &"thieves_tools" in character.skill_proficiencies:
			prof_bonus = character.get_proficiency_bonus()

	var result: DiceRoller.D20Result = DiceRoller.ability_check(dex_mod + prof_bonus)
	if result.total >= data.lock_dc:
		data.is_locked = false
		return true

	return false

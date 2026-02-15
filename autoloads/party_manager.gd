## Party roster management singleton.
##
## Registered as an autoload. Maintains the list of CharacterData resources
## that make up the player's adventuring party, and provides helpers for
## common party-wide queries and operations.
extends Node

# ===========================================================================
# State
# ===========================================================================

## The current party roster. Each element is a CharacterData Resource.
var party: Array[Resource] = []

## Maximum number of characters allowed in the active party.
var max_party_size: int = 4

## Index of the character the player is currently controlling.
var active_character_index: int = 0

# ===========================================================================
# Signals
# ===========================================================================

signal party_changed()

# ===========================================================================
# Roster management
# ===========================================================================

## Add a character to the party.
##
## Returns [code]true[/code] if the character was successfully added, or
## [code]false[/code] if the party is already full or the character is already
## a member.
func add_member(character: Resource) -> bool:
	if is_party_full():
		push_warning("PartyManager: Cannot add member -- party is full (%d/%d)." % [party.size(), max_party_size])
		return false

	if character in party:
		push_warning("PartyManager: Character '%s' is already in the party." % _get_character_name(character))
		return false

	party.append(character)
	EventBus.party_member_added.emit(character)
	party_changed.emit()
	return true


## Remove a character from the party.
##
## Returns [code]true[/code] if the character was found and removed.
func remove_member(character: Resource) -> bool:
	var idx := party.find(character)
	if idx == -1:
		push_warning("PartyManager: Character not found in party.")
		return false

	party.remove_at(idx)

	# Keep active_character_index in bounds.
	if active_character_index >= party.size() and party.size() > 0:
		active_character_index = party.size() - 1
	elif party.size() == 0:
		active_character_index = 0

	EventBus.party_member_removed.emit(character)
	party_changed.emit()
	return true


# ===========================================================================
# Active character
# ===========================================================================

## Return the currently active (player-controlled) character, or null.
func get_active_character() -> Resource:
	if party.is_empty() or active_character_index >= party.size():
		return null
	return party[active_character_index]


## Set the active character by index.
func set_active_character(index: int) -> void:
	if index >= 0 and index < party.size():
		active_character_index = index
	else:
		push_warning("PartyManager: Invalid active character index %d." % index)


# ===========================================================================
# Queries
# ===========================================================================

## Average level across the party (rounded down). Returns 0 if party is empty.
func get_party_level() -> int:
	if party.is_empty():
		return 0

	var total_level := 0
	for member in party:
		total_level += member.get("level") if member.get("level") else 1

	return int(floor(float(total_level) / float(party.size())))


## Current number of party members.
func get_party_size() -> int:
	return party.size()


## Whether the party has reached its maximum capacity.
func is_party_full() -> bool:
	return party.size() >= max_party_size


## Get a party member by index (returns null if out of range).
func get_member(index: int) -> Resource:
	if index >= 0 and index < party.size():
		return party[index]
	return null


## Find a party member by their [code]character_name[/code] property.
##
## Returns [code]null[/code] if no match is found. Comparison is
## case-insensitive.
func find_member_by_name(character_name: String) -> Resource:
	var lower_name := character_name.to_lower()
	for member in party:
		var name_value = _get_character_name(member)
		if name_value.to_lower() == lower_name:
			return member
	return null


# ===========================================================================
# Party-wide actions
# ===========================================================================

## Heal every party member by [code]amount[/code] hit points.
##
## Individual members are healed via their [code]heal()[/code] method if
## available; otherwise [code]current_hp[/code] is increased directly (capped
## at [code]max_hp[/code]).
func heal_party(amount: int) -> void:
	for member in party:
		if member.has_method("heal"):
			member.heal(amount)
		elif member.get("current_hp") != null and member.get("max_hp") != null:
			member.current_hp = mini(member.current_hp + amount, member.max_hp)
		EventBus.character_healed.emit(member, amount)


## Return the combined inventory weight across all party members.
##
## Each member is expected to expose either a [code]get_total_weight()[/code]
## method or an [code]inventory_weight[/code] property.
func get_total_weight() -> float:
	var total := 0.0
	for member in party:
		if member.has_method("get_total_weight"):
			total += member.get_total_weight()
		elif member.get("inventory_weight") != null:
			total += float(member.inventory_weight)
	return total


# ===========================================================================
# Private helpers
# ===========================================================================

## Safely retrieve a character's display name.
func _get_character_name(character: Resource) -> String:
	if character.get("character_name"):
		return str(character.character_name)
	if character.get("name"):
		return str(character.name)
	return "<unnamed>"

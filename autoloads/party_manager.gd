## Party roster management singleton.
##
## Registered as an autoload. Maintains the list of CharacterData resources
## that make up the player's adventuring party, and provides helpers for
## common party-wide queries and operations.
extends Node

# ===========================================================================
# State
# ===========================================================================

## The current party roster.
var party: Array[CharacterData] = []

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
func add_member(character: CharacterData) -> bool:
	if is_party_full():
		push_warning("PartyManager: Cannot add member -- party is full (%d/%d)." % [party.size(), max_party_size])
		return false

	if character in party:
		push_warning("PartyManager: Character '%s' is already in the party." % character.character_name)
		return false

	party.append(character)
	EventBus.party_member_added.emit(character)
	party_changed.emit()
	return true


## Remove a character from the party.
##
## Returns [code]true[/code] if the character was found and removed.
func remove_member(character: CharacterData) -> bool:
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
func get_active_character() -> CharacterData:
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
		total_level += member.level

	return int(floor(float(total_level) / float(party.size())))


## Current number of party members.
func get_party_size() -> int:
	return party.size()


## Whether the party has reached its maximum capacity.
func is_party_full() -> bool:
	return party.size() >= max_party_size


## Get a party member by index (returns null if out of range).
func get_member(index: int) -> CharacterData:
	if index >= 0 and index < party.size():
		return party[index]
	return null


## Find a party member by their [code]character_name[/code] property.
##
## Returns [code]null[/code] if no match is found. Comparison is
## case-insensitive.
func find_member_by_name(char_name: String) -> CharacterData:
	var lower_name := char_name.to_lower()
	for member in party:
		if member.character_name.to_lower() == lower_name:
			return member
	return null


# ===========================================================================
# Party-wide actions
# ===========================================================================

## Heal every party member by [code]amount[/code] hit points (capped at max_hp).
func heal_party(amount: int) -> void:
	for member in party:
		member.current_hp = mini(member.current_hp + amount, member.max_hp)
		EventBus.character_healed.emit(member, amount)


## Return the combined inventory weight across all party members.
func get_total_weight() -> float:
	var total := 0.0
	for member in party:
		total += InventorySystem.get_total_weight(member)
	return total



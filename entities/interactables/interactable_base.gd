class_name InteractableBase
extends Area2D

## Base class for all dungeon interactable objects.
##
## Provides interaction detection, highlight on hover, and emits
## EventBus.interaction_triggered when activated.

## The data resource defining this interactable's properties.
@export var interactable_data: InteractableData

## Whether this interactable can currently be used.
var is_active: bool = true

## Visual highlight state.
var _is_highlighted: bool = false


func _ready() -> void:
	# Set to interactable collision layer (layer 2).
	collision_layer = 0b0010
	collision_mask = 0

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

## Called when a character interacts with this object. Override in subclasses.
func interact() -> void:
	if not is_active:
		return

	if interactable_data and interactable_data.is_locked:
		if not _try_unlock():
			return

	_perform_interaction()
	EventBus.interaction_triggered.emit(self)


## Override in subclasses to implement specific behavior.
func _perform_interaction() -> void:
	pass


## Whether this interactable blocks character movement through its cell.
## Override in subclasses (e.g. closed doors block, open doors don't).
func blocks_movement() -> bool:
	return false


# ---------------------------------------------------------------------------
# Lock checking
# ---------------------------------------------------------------------------

func _try_unlock() -> bool:
	var character: Resource = PartyManager.get_active_character()
	if character == null:
		return false

	# Check if party has the key item.
	if interactable_data.key_item_id != &"":
		for entry in character.inventory:
			var item: Resource = entry.get("item") if entry is Dictionary else entry
			if item and item.get("id") == interactable_data.key_item_id:
				interactable_data.is_locked = false
				return true

	# Attempt Thieves' Tools check (DEX + proficiency if applicable).
	var dex_mod: int = character.get_modifier(&"dexterity")
	var prof_bonus: int = 0
	if character.get("skill_proficiencies") != null:
		if &"thieves_tools" in character.skill_proficiencies:
			prof_bonus = character.get_proficiency_bonus()

	var result: DiceRoller.D20Result = DiceRoller.ability_check(dex_mod + prof_bonus)
	if result.total >= interactable_data.lock_dc:
		interactable_data.is_locked = false
		return true

	return false


# ---------------------------------------------------------------------------
# Highlight
# ---------------------------------------------------------------------------

func highlight() -> void:
	if not _is_highlighted:
		_is_highlighted = true
		modulate = Color(1.3, 1.3, 1.0, 1.0)


func unhighlight() -> void:
	if _is_highlighted:
		_is_highlighted = false
		modulate = Color.WHITE


func _on_mouse_entered() -> void:
	highlight()


func _on_mouse_exited() -> void:
	unhighlight()

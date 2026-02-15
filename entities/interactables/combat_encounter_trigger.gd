class_name CombatEncounterTrigger
extends Node2D

## Placed on the grid dungeon. Triggers a combat encounter when a character
## enters a nearby cell. One-shot by default (can be made repeatable).

## The encounter data to trigger.
@export var encounter_id: StringName

## Trigger radius in cells (0 = same cell only, 1 = adjacent, etc.).
@export var trigger_radius: int = 1

## Whether this trigger has already fired.
var triggered: bool = false

## Grid cell this trigger occupies.
var trigger_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	# Connect to token movement for proximity detection.
	EventBus.interaction_triggered.connect(_on_any_interaction)


## Check if a character token has entered the trigger zone.
## Called by the GridDungeonController after each movement step.
func check_trigger(character_cell: Vector2i, controller: Node) -> bool:
	if triggered:
		return false

	var dx: int = absi(character_cell.x - trigger_cell.x)
	var dy: int = absi(character_cell.y - trigger_cell.y)
	var dist: int = maxi(dx, dy)

	if dist > trigger_radius:
		return false

	# Trigger the encounter.
	triggered = true
	_start_encounter(controller)
	return true


func _start_encounter(controller: Node) -> void:
	var encounter: CombatEncounterData = DataRegistry.get_encounter(encounter_id)
	if encounter == null:
		push_warning("CombatEncounterTrigger: Unknown encounter '%s'" % encounter_id)
		return

	if controller.has_method("start_encounter"):
		controller.start_encounter(encounter)


func _on_any_interaction(_interactable: Node) -> void:
	# Not used by default; subclasses could react to interactions.
	pass


## Setup helper for procedural placement.
func setup_trigger(cell: Vector2i, enc_id: StringName, radius: int = 1) -> void:
	trigger_cell = cell
	encounter_id = enc_id
	trigger_radius = radius

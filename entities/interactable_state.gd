class_name InteractableState
extends RefCounted

## Pure-logic state for interactable objects (doors, chests, levers).
##
## Tracks open/looted/activated/highlighted state without any visual code.
## Controllers or interactable nodes listen to state_changed to update visuals.

signal state_changed(property: StringName, value: Variant)

## Whether the interactable is open (doors).
var is_open: bool = false

## Whether the interactable has been looted (chests).
var is_looted: bool = false

## Whether the interactable is activated (levers).
var is_activated: bool = false

## Whether the interactable is visually highlighted.
var is_highlighted: bool = false


## Toggle open state (for doors).
func toggle_open() -> void:
	is_open = not is_open
	state_changed.emit(&"is_open", is_open)


## Mark as looted (for chests). One-way.
func set_looted() -> void:
	is_looted = true
	state_changed.emit(&"is_looted", true)


## Toggle activated state (for levers).
func toggle_activated() -> void:
	is_activated = not is_activated
	state_changed.emit(&"is_activated", is_activated)


## Set highlight state.
func set_highlighted(on: bool) -> void:
	if is_highlighted == on:
		return
	is_highlighted = on
	state_changed.emit(&"is_highlighted", on)

class_name DoorInteractable
extends InteractableBase

## A door that can be opened/closed and optionally locked.
##
## When locked, requires a Thieves' Tools check vs lock_dc or a key item.
## Open/close state affects pathfinding (closed doors block movement).

## Whether the door is currently open (delegates to state).
var is_open: bool:
	get: return state.is_open
	set(v): state.is_open = v

## Optional CollisionShape that blocks movement when closed.
@export var blocking_shape_path: NodePath


func _perform_interaction() -> void:
	state.toggle_open()
	_update_visual()

	if interactable_data:
		interactable_data.is_used = is_open

	var state_str: String = "opened" if is_open else "closed"
	var name_str: String = interactable_data.display_name if interactable_data else "Door"
	print("%s %s." % [name_str, state_str])


func blocks_movement() -> bool:
	return not is_open


## Force the door open without a check.
func force_open() -> void:
	state.is_open = true
	state.state_changed.emit(&"is_open", true)
	_update_visual()


## Force the door closed.
func force_close() -> void:
	state.is_open = false
	state.state_changed.emit(&"is_open", false)
	_update_visual()


## Apply visual state for the current open/closed status.
func _update_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) if is_open else Color.WHITE

	if blocking_shape_path != NodePath():
		var shape: Node = get_node_or_null(blocking_shape_path)
		if shape and shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = is_open

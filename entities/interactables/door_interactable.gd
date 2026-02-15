class_name DoorInteractable
extends InteractableBase

## A door that can be opened/closed and optionally locked.
##
## When locked, requires a Thieves' Tools check vs lock_dc or a key item.
## Open/close state affects pathfinding (closed doors block movement).

## Whether the door is currently open.
var is_open: bool = false

## Optional CollisionShape that blocks movement when closed.
@export var blocking_shape_path: NodePath


func _perform_interaction() -> void:
	is_open = not is_open

	# Update visual — darken when open to show it's no longer blocking.
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) if is_open else Color.WHITE

	# Enable/disable the blocking collision shape.
	if blocking_shape_path != NodePath():
		var shape: Node = get_node_or_null(blocking_shape_path)
		if shape and shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = is_open

	if interactable_data:
		interactable_data.is_used = is_open

	var state_str: String = "opened" if is_open else "closed"
	var name_str: String = interactable_data.display_name if interactable_data else "Door"
	print("%s %s." % [name_str, state_str])


func blocks_movement() -> bool:
	return not is_open


## Force the door open without a check.
func force_open() -> void:
	is_open = true
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	if blocking_shape_path != NodePath():
		var shape: Node = get_node_or_null(blocking_shape_path)
		if shape and shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = true
	print("Door forced open.")


## Force the door closed.
func force_close() -> void:
	is_open = false
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color.WHITE
	if blocking_shape_path != NodePath():
		var shape: Node = get_node_or_null(blocking_shape_path)
		if shape and shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = false
	print("Door forced closed.")

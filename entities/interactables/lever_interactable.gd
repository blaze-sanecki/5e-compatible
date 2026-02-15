class_name LeverInteractable
extends InteractableBase

## A lever that toggles linked objects on/off.
##
## Configure linked_objects with NodePaths to doors, traps, or other
## interactables. Pulling the lever calls interact() on each linked node.

## Paths to nodes that this lever controls.
@export var linked_objects: Array[NodePath] = []

## Whether the lever is currently in the "on" position (delegates to state).
var is_activated: bool:
	get: return state.is_activated
	set(v): state.is_activated = v


func _perform_interaction() -> void:
	state.toggle_activated()
	_update_visual()

	if interactable_data:
		interactable_data.is_used = is_activated

	var name_str: String = interactable_data.display_name if interactable_data else "Lever"
	var state_str: String = "activated" if is_activated else "deactivated"
	print("%s %s." % [name_str, state_str])

	# Toggle all linked objects.
	for path in linked_objects:
		var target: Node = get_node_or_null(path)
		if target == null:
			push_warning("LeverInteractable: Linked node not found at '%s'." % str(path))
			continue

		if target.has_method("force_open") and target.has_method("force_close"):
			# Direct door control without lock checks.
			if is_activated:
				target.force_open()
			else:
				target.force_close()
		elif target.has_method("interact"):
			target.interact()


## Apply visual state for the current activated status.
func _update_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(0.3, 1.0, 0.3) if is_activated else Color.WHITE

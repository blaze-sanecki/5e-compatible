class_name PortalArea
extends Area2D

## Detects when the party enters a portal zone and triggers a map transition.
##
## Place as a child of a dungeon or overworld scene. Configure portal_data
## to set the destination. Uses LockCheck for locked portals.

## The portal configuration.
@export var portal_data: PortalData

## Visual indicator (child sprite or label).
@export var show_indicator: bool = true

var _can_interact: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Set collision to interactable layer.
	collision_layer = 0b0010
	collision_mask = 0b0001  # Detect player bodies.


func _on_body_entered(_body: Node2D) -> void:
	_try_transition()


func _on_area_entered(_area: Area2D) -> void:
	_try_transition()


func _try_transition() -> void:
	if portal_data == null:
		push_warning("PortalArea: No portal_data assigned.")
		return

	if not _can_interact:
		return

	if portal_data.is_locked:
		if not LockCheck.try_unlock(portal_data):
			return

	_can_interact = false
	TransitionManager.transition_to(portal_data.target_map_path, portal_data.spawn_point, portal_data.transition_type)


## Allow the portal to be used again (called after returning to this map).
func reset() -> void:
	_can_interact = true


## Called by the dungeon controller when the player presses interact nearby.
func interact() -> void:
	_try_transition()

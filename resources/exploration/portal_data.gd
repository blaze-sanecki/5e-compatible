class_name PortalData
extends Resource

## Defines a map transition portal connecting two maps.
##
## Portals link hex overworld hexes to dungeon maps and vice versa.

## The scene path of the target map.
@export_file("*.tscn") var target_map_path: String

## Spawn point ID in the target map where the party appears.
@export var spawn_point: StringName = &"default"

## Whether this portal is locked (requires a key or check to open).
@export var is_locked: bool = false

## DC for the check to unlock (Thieves' Tools or key item).
@export var lock_dc: int = 15

## Type of transition animation.
@export_enum("fade", "slide", "instant") var transition_type: String = "fade"

## Optional display text when hovering the portal.
@export var hover_text: String = ""

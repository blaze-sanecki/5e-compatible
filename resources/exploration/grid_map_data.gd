class_name GridMapData
extends Resource

## Defines metadata for a square-grid dungeon map.
##
## Each cell represents a 5ft square. The map tracks spawn points
## for party entry and size constraints.

## Unique map identifier.
@export var map_id: StringName

## Display name shown in the UI.
@export var display_name: String

## Map description.
@export_multiline var description: String

## Map dimensions in cells.
@export var map_size: Vector2i = Vector2i(20, 20)

## Size of each cell in feet (standard 5e = 5ft).
@export var cell_size_feet: int = 5

## Named spawn points: key = spawn_id, value = cell position.
@export var spawn_points: Dictionary = {}

## Path back to the overworld map (used by exit portals).
@export var overworld_return_map: String = ""

## The cell to return to on the overworld when exiting.
@export var overworld_return_cell: Vector2i = Vector2i.ZERO

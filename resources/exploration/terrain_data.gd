class_name TerrainData
extends Resource

## Defines terrain properties for a hex tile type.
##
## Movement cost multiplier affects travel time and pathfinding. Encounter
## chance is checked each time the party enters a hex of this terrain.

## Unique terrain identifier.
@export var id: StringName

## Display name shown in the UI.
@export var display_name: String

## Description of the terrain type.
@export_multiline var description: String

## Multiplier applied to base movement cost (1.0 = normal, 2.0 = double).
@export var movement_cost_multiplier: float = 1.0

## Base chance (0.0–1.0) of a random encounter when entering this hex.
@export var base_encounter_chance: float = 0.0

## Optional effects applied while traveling through this terrain.
## Each entry is a Dictionary with keys like "stealth_modifier", "perception_modifier".
@export var travel_effects: Array[Dictionary] = []

## TileSet source ID for this terrain (set when building the tilemap).
@export var tile_source_id: int = -1

## Atlas coordinates within the tile source.
@export var tile_atlas_coords: Vector2i = Vector2i.ZERO

class_name HexTilemapManager
extends RefCounted

## Wraps a TileMapLayer for hex grid operations.
##
## Provides terrain lookups, coordinate conversions, and highlight helpers.
## Works with pointy-top hex tiles.

## Mapping from tile source/atlas to TerrainData.
var _terrain_map: Dictionary = {}

## Reference to the terrain TileMapLayer.
var _terrain_layer: TileMapLayer


func _init(terrain_layer: TileMapLayer) -> void:
	_terrain_layer = terrain_layer


# ---------------------------------------------------------------------------
# Terrain registration
# ---------------------------------------------------------------------------

## Register a TerrainData so tiles with matching source/atlas map to it.
func register_terrain(terrain: TerrainData) -> void:
	var key: String = "%d_%d_%d" % [terrain.tile_source_id, terrain.tile_atlas_coords.x, terrain.tile_atlas_coords.y]
	_terrain_map[key] = terrain


## Register all terrains from an array.
func register_terrains(terrains: Array) -> void:
	for terrain in terrains:
		register_terrain(terrain)


# ---------------------------------------------------------------------------
# Terrain queries
# ---------------------------------------------------------------------------

## Return the TerrainData for the tile at the given cell, or null.
func get_terrain_at(cell: Vector2i) -> TerrainData:
	var source_id: int = _terrain_layer.get_cell_source_id(cell)
	if source_id == -1:
		return null
	var atlas_coords: Vector2i = _terrain_layer.get_cell_atlas_coords(cell)
	var key: String = "%d_%d_%d" % [source_id, atlas_coords.x, atlas_coords.y]
	return _terrain_map.get(key) as TerrainData


## Return the movement cost multiplier at the given cell (defaults to 1.0).
func get_movement_cost(cell: Vector2i) -> float:
	var terrain: TerrainData = get_terrain_at(cell)
	if terrain == null:
		return 1.0
	return terrain.movement_cost_multiplier


## Return whether a cell has a valid terrain tile (is walkable).
func is_valid_cell(cell: Vector2i) -> bool:
	return _terrain_layer.get_cell_source_id(cell) != -1


# ---------------------------------------------------------------------------
# Coordinate helpers
# ---------------------------------------------------------------------------

## Convert a world position to the corresponding hex cell.
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return _terrain_layer.local_to_map(world_pos)


## Convert a hex cell to the center world position.
func cell_to_world(cell: Vector2i) -> Vector2:
	return _terrain_layer.map_to_local(cell)


## Return all used (placed) cells in the terrain layer.
func get_used_cells() -> Array[Vector2i]:
	return _terrain_layer.get_used_cells()


# ---------------------------------------------------------------------------
# Highlight helpers
# ---------------------------------------------------------------------------

## Set tiles on a highlight layer for the given cells.
func highlight_cells(highlight_layer: TileMapLayer, cells: Array, source_id: int, atlas_coords: Vector2i = Vector2i.ZERO) -> void:
	for cell in cells:
		highlight_layer.set_cell(cell, source_id, atlas_coords)


## Clear all highlighted cells on a layer.
func clear_highlights(highlight_layer: TileMapLayer) -> void:
	highlight_layer.clear()


## Highlight a path (array of Vector2i cells) on the given layer.
func highlight_path(highlight_layer: TileMapLayer, path: Array, source_id: int, atlas_coords: Vector2i = Vector2i.ZERO) -> void:
	clear_highlights(highlight_layer)
	highlight_cells(highlight_layer, path, source_id, atlas_coords)

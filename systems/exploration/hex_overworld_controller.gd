class_name HexOverworldController
extends Node2D

## Root controller for the hex overworld map scene.
##
## Orchestrates input handling, pathfinding, party movement, encounter checks,
## and fog of war updates. Expects child nodes: TerrainLayer, FogLayer,
## HighlightLayer, PartyToken, Camera2D.

# ---------------------------------------------------------------------------
# Node references (assigned in _ready or via export)
# ---------------------------------------------------------------------------

@export var terrain_layer_path: NodePath
@export var fog_layer_path: NodePath
@export var highlight_layer_path: NodePath
@export var party_token_path: NodePath
@export var camera_path: NodePath

## Highlight tile source ID and atlas coords for path preview.
@export var highlight_source_id: int = 0
@export var highlight_atlas_coords: Vector2i = Vector2i.ZERO

var terrain_layer: TileMapLayer
var fog_layer: TileMapLayer
var highlight_layer: TileMapLayer
var party_token: PartyToken
var camera: Camera2D

## Sub-systems.
var tilemap_manager: HexTilemapManager
var pathfinder: HexPathfinding
var travel_system: OverworldTravelSystem
var fog_system: FogOfWarSystem
var vision_calc: VisionCalculator

## Current hovered cell for path preview.
var _hovered_cell: Vector2i = Vector2i(-9999, -9999)

## Current preview path.
var _preview_path: Array[Vector2i] = []

## Vision range in hex cells.
@export var vision_range: int = 3

## Generate a placeholder test map if the terrain layer is empty.
@export var generate_test_map: bool = true

## Radius of the generated test map in hexes.
@export var test_map_radius: int = 10


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	terrain_layer = get_node(terrain_layer_path) as TileMapLayer
	fog_layer = get_node(fog_layer_path) as TileMapLayer
	highlight_layer = get_node(highlight_layer_path) as TileMapLayer
	party_token = get_node(party_token_path) as PartyToken
	camera = get_node(camera_path) as Camera2D

	# If no tiles are placed, generate a test map with placeholder graphics.
	if generate_test_map and terrain_layer.get_used_cells().is_empty():
		var portal: Node = get_node_or_null("DungeonPortal")
		TestMapGenerator.generate_hex_overworld(
			terrain_layer, highlight_layer, fog_layer,
			party_token, portal, test_map_radius
		)

	# Initialize sub-systems.
	tilemap_manager = HexTilemapManager.new(terrain_layer)

	# Register terrains from DataRegistry.
	var terrains: Array = DataRegistry.get_all_terrains()
	tilemap_manager.register_terrains(terrains)

	pathfinder = HexPathfinding.new(tilemap_manager)
	travel_system = OverworldTravelSystem.new()

	fog_system = FogOfWarSystem.new()
	vision_calc = VisionCalculator.new()

	# Setup party token at a default position.
	var used_cells: Array[Vector2i] = tilemap_manager.get_used_cells()
	var start_cell: Vector2i = used_cells[0] if not used_cells.is_empty() else Vector2i.ZERO
	party_token.setup(tilemap_manager, start_cell)

	# Connect party token signals.
	party_token.hex_entered.connect(_on_hex_entered)
	party_token.movement_completed.connect(_on_movement_completed)

	# Initialize fog of war.
	fog_system.initialize_hex(fog_layer, used_cells)
	_update_fog()

	# Center camera on party.
	camera.position = party_token.position

	# Wire up pace selector if present.
	var pace_selector: Node = _find_pace_selector()
	if pace_selector and pace_selector.has_method("setup"):
		pace_selector.setup(travel_system)

	GameManager.change_state(GameManager.GameState.EXPLORING)


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_exploring():
		return
	if party_token.is_moving:
		return

	if event is InputEventMouseMotion:
		_handle_mouse_hover(event as InputEventMouseMotion)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb)


# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------

func _handle_mouse_hover(event: InputEventMouseMotion) -> void:
	var world_pos: Vector2 = _screen_to_world(event.position)
	var cell: Vector2i = tilemap_manager.world_to_cell(world_pos)

	if cell == _hovered_cell:
		return
	_hovered_cell = cell

	if not tilemap_manager.is_valid_cell(cell) or cell == party_token.current_cell:
		tilemap_manager.clear_highlights(highlight_layer)
		_preview_path.clear()
		return

	_preview_path = pathfinder.find_path(party_token.current_cell, cell)
	if _preview_path.is_empty():
		tilemap_manager.clear_highlights(highlight_layer)
	else:
		tilemap_manager.highlight_path(highlight_layer, _preview_path, highlight_source_id, highlight_atlas_coords)


func _handle_click(event: InputEventMouseButton) -> void:
	var world_pos: Vector2 = _screen_to_world(event.position)
	var cell: Vector2i = tilemap_manager.world_to_cell(world_pos)

	if not tilemap_manager.is_valid_cell(cell):
		return
	if cell == party_token.current_cell:
		return

	var path: Array[Vector2i] = pathfinder.find_path(party_token.current_cell, cell)
	if path.is_empty():
		return

	tilemap_manager.clear_highlights(highlight_layer)
	party_token.move_along_path(path)


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos


# ---------------------------------------------------------------------------
# Movement callbacks
# ---------------------------------------------------------------------------

func _on_hex_entered(cell: Vector2i) -> void:
	var terrain: TerrainData = tilemap_manager.get_terrain_at(cell)
	if terrain == null:
		return

	# Process travel (time, encounters).
	var result: Dictionary = travel_system.process_hex_entered(terrain)

	# Update fog of war.
	_update_fog()

	# Follow with camera.
	_update_camera()

	# Check for encounters.
	if result["encounter_triggered"]:
		party_token.is_moving = false
		if party_token._move_tween and party_token._move_tween.is_running():
			party_token._move_tween.kill()
		EventBus.combat_started.emit()


func _on_movement_completed() -> void:
	_update_camera()


# ---------------------------------------------------------------------------
# Fog of war
# ---------------------------------------------------------------------------

func _update_fog() -> void:
	var center_cube: Vector3i = HexCoords.axial_to_cube(party_token.current_cell)
	var visible_cubes: Array[Vector3i] = HexCoords.cube_spiral(center_cube, vision_range)

	var visible_cells: Array[Vector2i] = []
	for cube in visible_cubes:
		var cell: Vector2i = HexCoords.cube_to_axial(cube)
		if tilemap_manager.is_valid_cell(cell):
			visible_cells.append(cell)

	fog_system.update_visibility(visible_cells)


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	if camera == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(camera, "position", party_token.position, 0.3).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Spawn the party token at a specific cell.
func spawn_party_at(cell: Vector2i) -> void:
	party_token.teleport_to(cell)
	_update_fog()
	_update_camera()


## Set the travel pace via the travel system.
func set_travel_pace(pace: OverworldTravelSystem.TravelPace) -> void:
	travel_system.set_pace(pace)


func _find_pace_selector() -> Node:
	for child in get_children():
		if child is CanvasLayer:
			for ui_child in child.get_children():
				if ui_child.has_method("setup"):
					return ui_child
	return null

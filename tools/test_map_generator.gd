class_name TestMapGenerator
extends RefCounted

## Procedural test map generator for development/testing.
##
## Creates placeholder tilesets, tiles, sprites, and interactable
## configurations so maps can be tested without art assets.
## Completely separate from production game code.


# ===========================================================================
# Shared helpers
# ===========================================================================

## Create a solid-color ImageTexture of the given size.
static func create_solid_texture(size: Vector2i, color: Color) -> ImageTexture:
	var img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


## Create a diamond-shaped sprite texture.
static func create_diamond_texture(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size * 0.4
	for y in size:
		for x in size:
			var dx: float = absf(float(x) - center.x)
			var dy: float = absf(float(y) - center.y)
			if dx / radius + dy / radius <= 1.0:
				img.set_pixel(x, y, color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


## Create a circle sprite texture.
static func create_circle_texture(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	for y in size:
		for x in size:
			var dist: float = Vector2(x, y).distance_to(center)
			if dist <= size * 0.4:
				img.set_pixel(x, y, color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


## Create a bordered square sprite texture with a letter.
static func create_labeled_square_texture(size: int, color: Color) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	for i in size:
		img.set_pixel(i, 0, color.darkened(0.4))
		img.set_pixel(i, size - 1, color.darkened(0.4))
		img.set_pixel(0, i, color.darkened(0.4))
		img.set_pixel(size - 1, i, color.darkened(0.4))
	return ImageTexture.create_from_image(img)


## Add a Sprite2D child with the given texture, removing any existing one.
static func set_sprite(node: Node, tex: ImageTexture) -> Sprite2D:
	var old: Sprite2D = node.get_node_or_null("Sprite2D")
	if old:
		old.queue_free()
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = tex
	node.add_child(sprite)
	return sprite


## Add a Label child to a node.
static func add_label(node: Node, text: String, offset: Vector2 = Vector2(-6, -10), font_size: int = 14) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = offset
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	node.add_child(label)


## Set up a collision shape on an Area2D node.
static func setup_rect_collision(node: Node, size: Vector2) -> void:
	var col: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	if col:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = size
		col.shape = rect


static func setup_circle_collision(node: Node, radius: float) -> void:
	var col: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	if col:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = radius
		col.shape = circle


# ===========================================================================
# Hex overworld generation
# ===========================================================================

## Draw a filled hexagon into an image atlas at the given offset.
static func draw_hex_tile(img: Image, ox: int, oy: int, size: int, color: Color) -> void:
	var center: Vector2 = Vector2(ox + size / 2.0, oy + size / 2.0)
	var radius: float = size * 0.45
	for y in range(oy, oy + size):
		for x in range(ox, ox + size):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	for y in range(oy, oy + size):
		for x in range(ox, ox + size):
			var dx: float = absf(float(x) - center.x)
			var dy: float = absf(float(y) - center.y)
			if dx <= radius * 0.866 and dy <= radius:
				if dy <= radius - dx * 0.577:
					var edge_factor: float = 1.0 - (dx + dy) / (radius * 1.8)
					var c: Color = color.lerp(color.darkened(0.3), 1.0 - clampf(edge_factor, 0.5, 1.0))
					img.set_pixel(x, y, c)


## Generate the full hex overworld: tilesets, terrain tiles, fog, party sprite, portal.
static func generate_hex_overworld(
	terrain_layer: TileMapLayer,
	highlight_layer: TileMapLayer,
	fog_layer: TileMapLayer,
	party_token: Node2D,
	portal_node: Node,
	map_radius: int
) -> void:
	var tile_px: int = 64

	# -- Terrain TileSet --
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	tile_set.tile_layout = TileSet.TILE_LAYOUT_STACKED
	tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	tile_set.tile_size = Vector2i(tile_px, tile_px)

	var terrain_colors: Array[Color] = [
		Color(0.4, 0.75, 0.3),   # 0: plains
		Color(0.15, 0.45, 0.15), # 1: forest
		Color(0.7, 0.6, 0.35),   # 2: hills
		Color(0.5, 0.5, 0.55),   # 3: mountains
		Color(0.4, 0.3, 0.5),    # 4: swamp
	]

	var atlas_img: Image = Image.create(tile_px * 5, tile_px, false, Image.FORMAT_RGBA8)
	for i in terrain_colors.size():
		draw_hex_tile(atlas_img, i * tile_px, 0, tile_px, terrain_colors[i])

	var atlas_source: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas_source.texture = ImageTexture.create_from_image(atlas_img)
	atlas_source.texture_region_size = Vector2i(tile_px, tile_px)
	for i in 5:
		atlas_source.create_tile(Vector2i(i, 0))
	tile_set.add_source(atlas_source, 0)

	terrain_layer.tile_set = tile_set
	highlight_layer.tile_set = tile_set
	fog_layer.tile_set = _create_hex_fog_tileset(tile_px)

	# -- Place terrain --
	var all_cubes: Array[Vector3i] = HexCoords.cube_spiral(Vector3i.ZERO, map_radius)
	for cube in all_cubes:
		var axial: Vector2i = HexCoords.cube_to_axial(cube)
		var dist: int = HexCoords.cube_distance(Vector3i.ZERO, cube)
		var idx: int = _pick_terrain(axial, dist, map_radius)
		terrain_layer.set_cell(axial, 0, Vector2i(idx, 0))

	# -- Party token sprite --
	var sprite: Sprite2D = party_token.get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture = create_diamond_texture(24, Color(1, 0.9, 0.2, 1))

	# -- Dungeon portal --
	if portal_node:
		_setup_hex_portal(portal_node, terrain_layer, tile_px)

	print("TestMapGenerator: Hex overworld generated (%d hexes, radius %d)." % [all_cubes.size(), map_radius])


static func _create_hex_fog_tileset(tile_px: int) -> TileSet:
	var fog_tileset: TileSet = TileSet.new()
	fog_tileset.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	fog_tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED
	fog_tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	fog_tileset.tile_size = Vector2i(tile_px, tile_px)

	var fog_img: Image = Image.create(tile_px * 2, tile_px, false, Image.FORMAT_RGBA8)
	draw_hex_tile(fog_img, 0, 0, tile_px, Color(0, 0, 0, 1))
	draw_hex_tile(fog_img, tile_px, 0, tile_px, Color(0, 0, 0, 0.5))

	var fog_atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	fog_atlas.texture = ImageTexture.create_from_image(fog_img)
	fog_atlas.texture_region_size = Vector2i(tile_px, tile_px)
	fog_atlas.create_tile(Vector2i(0, 0))
	fog_atlas.create_tile(Vector2i(1, 0))
	fog_tileset.add_source(fog_atlas, 0)
	return fog_tileset


static func _pick_terrain(axial: Vector2i, dist: int, map_radius: int) -> int:
	var hash_val: int = absi(axial.x * 7 + axial.y * 13 + axial.x * axial.y * 3)
	if dist >= map_radius - 1:
		return 3  # mountains
	if dist <= 2:
		return 0  # plains
	var roll: int = hash_val % 10
	if roll < 4: return 0       # plains 40%
	elif roll < 6: return 1     # forest 20%
	elif roll < 8: return 2     # hills 20%
	elif roll < 9: return 4     # swamp 10%
	else: return 3              # mountains 10%


static func _setup_hex_portal(portal: Node, terrain_layer: TileMapLayer, _tile_px: int) -> void:
	var portal_cell: Vector2i = Vector2i(4, 3)
	portal.position = terrain_layer.map_to_local(portal_cell)

	var sprite: Sprite2D = set_sprite(portal, create_diamond_texture(32, Color(0.1, 0.9, 0.9, 0.9)))
	sprite.z_index = 4

	add_label(portal, "Dungeon", Vector2(-24, -28), 10)
	setup_circle_collision(portal, 20.0)

	if portal.get("portal_data") != null or portal.has_method("interact"):
		var pdata: PortalData = PortalData.new()
		pdata.target_map_path = "res://maps/dungeons/test_dungeon.tscn"
		pdata.spawn_point = &"default"
		pdata.transition_type = "fade"
		portal.portal_data = pdata


# ===========================================================================
# Grid dungeon generation
# ===========================================================================

## Generate the full grid dungeon: tilesets, rooms, walls, fog, interactables, token.
static func generate_grid_dungeon(
	floor_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	fog_layer: TileMapLayer,
	interactables_node: Node,
	controller: Node2D,
) -> CharacterToken:
	var tile_px: int = 32

	# -- Floor TileSet --
	var floor_tileset: TileSet = TileSet.new()
	floor_tileset.tile_size = Vector2i(tile_px, tile_px)
	var floor_img: Image = Image.create(tile_px, tile_px, false, Image.FORMAT_RGBA8)
	floor_img.fill(Color(0.35, 0.3, 0.28))
	for i in tile_px:
		floor_img.set_pixel(i, 0, Color(0.25, 0.22, 0.2))
		floor_img.set_pixel(0, i, Color(0.25, 0.22, 0.2))
	var floor_atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	floor_atlas.texture = ImageTexture.create_from_image(floor_img)
	floor_atlas.texture_region_size = Vector2i(tile_px, tile_px)
	floor_atlas.create_tile(Vector2i(0, 0))
	floor_tileset.add_source(floor_atlas, 0)
	floor_layer.tile_set = floor_tileset

	# -- Wall TileSet --
	var wall_tileset: TileSet = TileSet.new()
	wall_tileset.tile_size = Vector2i(tile_px, tile_px)
	var wall_atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	wall_atlas.texture = create_solid_texture(Vector2i(tile_px, tile_px), Color(0.15, 0.12, 0.1))
	wall_atlas.texture_region_size = Vector2i(tile_px, tile_px)
	wall_atlas.create_tile(Vector2i(0, 0))
	wall_tileset.add_source(wall_atlas, 0)
	wall_layer.tile_set = wall_tileset

	# -- Fog TileSet --
	var fog_tileset: TileSet = TileSet.new()
	fog_tileset.tile_size = Vector2i(tile_px, tile_px)
	var fog_img: Image = Image.create(tile_px * 2, tile_px, false, Image.FORMAT_RGBA8)
	for y in tile_px:
		for x in tile_px:
			fog_img.set_pixel(x, y, Color(0, 0, 0, 1))
	for y in tile_px:
		for x in range(tile_px, tile_px * 2):
			fog_img.set_pixel(x, y, Color(0, 0, 0, 0.5))
	var fog_atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	fog_atlas.texture = ImageTexture.create_from_image(fog_img)
	fog_atlas.texture_region_size = Vector2i(tile_px, tile_px)
	fog_atlas.create_tile(Vector2i(0, 0))
	fog_atlas.create_tile(Vector2i(1, 0))
	fog_tileset.add_source(fog_atlas, 0)
	fog_layer.tile_set = fog_tileset

	# -- Room layout --
	# Room 1: (1,1)-(6,6), Corridor: (7,3)-(9,4), Room 2: (10,1)-(14,7)
	_fill_rect(floor_layer, Vector2i(1, 1), Vector2i(6, 6))
	_fill_rect(floor_layer, Vector2i(7, 3), Vector2i(9, 4))
	_fill_rect(floor_layer, Vector2i(10, 1), Vector2i(14, 7))

	# Walls around floor perimeter.
	for x in range(0, 16):
		for y in range(0, 9):
			var cell: Vector2i = Vector2i(x, y)
			if floor_layer.get_cell_source_id(cell) == -1:
				for dir in GridPathfinding.DIRS_8:
					if floor_layer.get_cell_source_id(cell + dir) != -1:
						wall_layer.set_cell(cell, 0, Vector2i(0, 0))
						break

	# -- Interactables --
	if interactables_node:
		_setup_dungeon_interactables(interactables_node, floor_layer, tile_px)

	# -- Test character token --
	var token: CharacterToken = _create_test_token(controller, floor_layer)

	print("TestMapGenerator: Grid dungeon generated (2 rooms + corridor).")
	return token


static func _fill_rect(layer: TileMapLayer, from: Vector2i, to: Vector2i) -> void:
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))


static func _setup_dungeon_interactables(parent: Node, floor_layer: TileMapLayer, tile_px: int) -> void:
	var sq_size: int = tile_px - 4

	# Door at corridor/room2 junction (10, 3).
	var door: Node = parent.get_node_or_null("Door1")
	if door:
		door.position = floor_layer.map_to_local(Vector2i(10, 3))
		set_sprite(door, create_labeled_square_texture(sq_size, Color(0.6, 0.35, 0.1)))
		add_label(door, "D")
		setup_rect_collision(door, Vector2(sq_size, sq_size))
		var dd: InteractableData = InteractableData.new()
		dd.id = &"test_door_1"
		dd.display_name = "Locked Door"
		dd.type = InteractableData.InteractableType.DOOR
		dd.is_locked = true
		dd.lock_dc = 12
		door.interactable_data = dd

	# Chest in room 2 (12, 2).
	var chest: Node = parent.get_node_or_null("Chest1")
	if chest:
		chest.position = floor_layer.map_to_local(Vector2i(12, 2))
		set_sprite(chest, create_labeled_square_texture(sq_size, Color(0.8, 0.65, 0.1)))
		add_label(chest, "C")
		setup_rect_collision(chest, Vector2(sq_size, sq_size))
		var cd: InteractableData = InteractableData.new()
		cd.id = &"test_chest_1"
		cd.display_name = "Treasure Chest"
		cd.type = InteractableData.InteractableType.CHEST
		cd.loot_table = [
			{"item_id": &"gold", "quantity": 25, "chance": 1.0},
			{"item_id": &"dagger", "quantity": 1, "chance": 0.5},
		]
		chest.interactable_data = cd

	# Lever in room 1 (2, 2), linked to door.
	var lever: Node = parent.get_node_or_null("Lever1")
	if lever:
		lever.position = floor_layer.map_to_local(Vector2i(2, 2))
		set_sprite(lever, create_labeled_square_texture(sq_size, Color(0.5, 0.5, 0.7)))
		add_label(lever, "L")
		setup_rect_collision(lever, Vector2(sq_size, sq_size))
		var ld: InteractableData = InteractableData.new()
		ld.id = &"test_lever_1"
		ld.display_name = "Wall Lever"
		ld.type = InteractableData.InteractableType.LEVER
		lever.interactable_data = ld

	# Exit portal in room 2 (13, 6).
	var exit_portal: Node = parent.get_node_or_null("ExitPortal")
	if exit_portal:
		exit_portal.position = floor_layer.map_to_local(Vector2i(13, 6))
		set_sprite(exit_portal, create_labeled_square_texture(sq_size, Color(0.1, 0.9, 0.9)))
		add_label(exit_portal, "E")
		setup_rect_collision(exit_portal, Vector2(sq_size, sq_size))
		if exit_portal.get("portal_data") != null or exit_portal.has_method("interact"):
			var pd: PortalData = PortalData.new()
			pd.target_map_path = "res://maps/overworld/test_overworld.tscn"
			pd.spawn_point = &"default"
			pd.transition_type = "fade"
			exit_portal.portal_data = pd


static func _create_test_token(parent: Node2D, floor_layer: TileMapLayer) -> CharacterToken:
	var token: CharacterToken = CharacterToken.new()
	token.name = "TestCharToken"
	parent.add_child(token)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = create_circle_texture(20, Color(0.2, 0.6, 1.0, 1.0))
	token.add_child(sprite)

	token.setup(null, floor_layer, Vector2i(3, 3))
	return token

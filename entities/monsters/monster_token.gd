class_name MonsterToken
extends Node2D

## Visual representation of a monster on a square grid dungeon.
## Simpler than CharacterToken — no exploration input, just movement and effects.

signal moved_to(cell: Vector2i)
signal death_animation_finished()

## The MonsterData resource this token represents.
var monster_data: MonsterData

## Current grid cell position.
var current_cell: Vector2i = Vector2i.ZERO

## Whether the token is currently animating a move.
var is_moving: bool = false

## Movement speed in pixels per second.
var move_speed: float = 200.0

## Reference to the floor layer for coordinate conversion.
var _floor_layer: TileMapLayer

## Current movement tween.
var _move_tween: Tween

## The sprite child.
var _sprite: Sprite2D

## Original modulate for flash effects.
var _base_modulate: Color = Color.WHITE


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Initialize the monster token.
func setup(data: MonsterData, floor_layer: TileMapLayer, start_cell: Vector2i) -> void:
	monster_data = data
	_floor_layer = floor_layer
	current_cell = start_cell
	position = floor_layer.map_to_local(start_cell)

	# Create a sprite if one doesn't exist.
	_sprite = get_node_or_null("Sprite2D")
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)

	# Generate a placeholder sprite based on monster type.
	_sprite.texture = _create_monster_texture(data)

	# Add a name label.
	var label := Label.new()
	label.name = "NameLabel"
	label.text = data.display_name.left(3).to_upper()
	label.position = Vector2(-10, -18)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Move to a target cell with animation. Returns true if move started.
func move_to_cell(target_cell: Vector2i) -> bool:
	if is_moving or _floor_layer == null:
		return false

	is_moving = true
	var target_pos: Vector2 = _floor_layer.map_to_local(target_cell)
	var distance: float = position.distance_to(target_pos)
	var duration: float = distance / move_speed

	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target_pos, duration)
	_move_tween.finished.connect(func() -> void:
		current_cell = target_cell
		is_moving = false
		moved_to.emit(target_cell)
	)
	return true


## Move along a path of cells.
func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return
	_move_path_step(path, 1)


func _move_path_step(path: Array[Vector2i], index: int) -> void:
	if index >= path.size():
		return
	if not move_to_cell(path[index]):
		return
	await moved_to
	if index + 1 < path.size():
		_move_path_step(path, index + 1)


## Teleport without animation.
func teleport_to(cell: Vector2i) -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	current_cell = cell
	position = _floor_layer.map_to_local(cell)
	is_moving = false


# ---------------------------------------------------------------------------
# Visual effects
# ---------------------------------------------------------------------------

## Flash red when taking damage.
func flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	tween.tween_property(self, "modulate", _base_modulate, 0.2)


## Play death animation (fade out and shrink).
func play_death() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.5)
	tween.chain().tween_callback(func() -> void:
		death_animation_finished.emit()
		queue_free()
	)


# ---------------------------------------------------------------------------
# Placeholder visuals
# ---------------------------------------------------------------------------

func _create_monster_texture(data: MonsterData) -> ImageTexture:
	var size: int = 24
	var color: Color = _monster_color(data.creature_type)

	# Large creatures get a bigger sprite.
	if data.size == &"large":
		size = 32
	elif data.size == &"huge" or data.size == &"gargantuan":
		size = 48

	return TestMapGenerator.create_circle_texture(size, color)


func _monster_color(creature_type: StringName) -> Color:
	match creature_type:
		&"humanoid": return Color(0.9, 0.3, 0.2)
		&"undead": return Color(0.5, 0.7, 0.5)
		&"beast": return Color(0.7, 0.5, 0.2)
		&"giant": return Color(0.6, 0.3, 0.6)
		&"fiend": return Color(0.8, 0.1, 0.1)
		&"dragon": return Color(0.9, 0.6, 0.1)
		_: return Color(0.8, 0.4, 0.4)

class_name MonsterToken
extends AnimatedToken2D

## Pure visual representation of a monster on a square grid dungeon.
##
## No game logic — combat logic lives in CombatantData.
## Controllers create this, call setup_visual(), and drive movement
## via animate_move_to().

signal death_animation_finished()

## The MonsterData resource this token represents.
var monster_data: MonsterData

## The sprite child.
var _sprite: Sprite2D

## Original modulate for flash effects.
var _base_modulate: Color = Color.WHITE


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Initialize the monster token visuals at a world position.
func setup_visual(data: MonsterData, world_pos: Vector2) -> void:
	monster_data = data
	position = world_pos

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
# Visual interface
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

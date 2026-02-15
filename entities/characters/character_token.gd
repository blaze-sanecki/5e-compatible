class_name CharacterToken
extends AnimatedToken2D

## Pure visual representation of a single character on a square grid dungeon.
##
## No game logic — controllers pair this with a GridEntityState for cell
## tracking, movement budget, and selection state.

## The CharacterData resource this token represents.
@export var character_data: Resource


func _init() -> void:
	move_speed = 300.0


# ---------------------------------------------------------------------------
# Visual interface
# ---------------------------------------------------------------------------

## Set the selected highlight visual on or off.
func set_selected_visual(on: bool) -> void:
	modulate = Color(1.2, 1.2, 1.0, 1.0) if on else Color.WHITE


## Flash red when taking damage.
func flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

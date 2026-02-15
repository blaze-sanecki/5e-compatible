class_name AnimatedToken2D
extends Node2D

## Base class for animated tokens on the game map.
##
## Provides shared movement tweening (animate_move_to, teleport_visual)
## so that CharacterToken, PartyToken, and MonsterToken stay DRY.

signal animation_finished()

## Movement speed in pixels per second for tweening.
@export var move_speed: float = 200.0

## Current movement tween.
var _move_tween: Tween


# ---------------------------------------------------------------------------
# Visual interface
# ---------------------------------------------------------------------------

## Smoothly animate to a world position. Emits animation_finished when done.
func animate_move_to(world_pos: Vector2) -> void:
	var distance: float = position.distance_to(world_pos)
	var duration: float = distance / move_speed

	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", world_pos, duration)
	_move_tween.finished.connect(func() -> void:
		animation_finished.emit()
	)


## Snap to a world position instantly (no animation).
func teleport_visual(world_pos: Vector2) -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	position = world_pos


## Stop any in-progress movement animation.
func stop_animation() -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

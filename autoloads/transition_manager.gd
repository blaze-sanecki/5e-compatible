extends Node

## Autoload singleton managing map transitions with visual effects.
##
## Handles fade-to-black transitions between hex overworld and grid dungeons.
## Coordinates with GameManager.load_map() for scene loading.

# ---------------------------------------------------------------------------
# Fade overlay
# ---------------------------------------------------------------------------

## The ColorRect used for fade effects. Created on _ready.
var _fade_rect: ColorRect

## Duration of fade in/out in seconds.
var fade_duration: float = 0.5

## The spawn point to use in the target map.
var _pending_spawn_point: StringName = &"default"

## Whether a transition is currently in progress.
var is_transitioning: bool = false


func _ready() -> void:
	# Create a full-screen fade overlay on a high CanvasLayer.
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cover entire viewport.
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	canvas_layer.add_child(_fade_rect)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Transition to a new map with the specified effect.
##
## [code]map_path[/code]: path to the target .tscn file.
## [code]spawn_point[/code]: spawn ID in the target map.
## [code]transition_type[/code]: "fade", "slide", or "instant".
func transition_to(map_path: String, spawn_point: StringName = &"default", transition_type: String = "fade") -> void:
	if is_transitioning:
		return

	is_transitioning = true
	_pending_spawn_point = spawn_point

	match transition_type:
		"fade":
			await _fade_out()
			await _load_and_spawn(map_path)
			await _fade_in()
		"instant":
			await _load_and_spawn(map_path)
		_:
			await _fade_out()
			await _load_and_spawn(map_path)
			await _fade_in()

	is_transitioning = false


# ---------------------------------------------------------------------------
# Fade effects
# ---------------------------------------------------------------------------

func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished


func _fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished


# ---------------------------------------------------------------------------
# Scene loading
# ---------------------------------------------------------------------------

func _load_and_spawn(map_path: String) -> void:
	# Use GameManager's load_map which handles state changes and signals.
	await GameManager.load_map(map_path)

	# Wait a frame for the new scene to initialize.
	await get_tree().process_frame

	# Find the new scene root and tell it where to spawn the party.
	var new_scene: Node = get_tree().current_scene
	if new_scene == null:
		return

	# Hex overworld controller.
	if new_scene.has_method("spawn_party_at"):
		var spawn_cell: Vector2i = Vector2i.ZERO
		# Try to get spawn from portal data or scene metadata.
		if new_scene.get("map_data") and new_scene.map_data and new_scene.map_data.get("spawn_points"):
			var points: Dictionary = new_scene.map_data.spawn_points
			if points.has(_pending_spawn_point):
				spawn_cell = points[_pending_spawn_point]
		new_scene.spawn_party_at(spawn_cell)

	# Grid dungeon controller.
	elif new_scene.has_method("spawn_party"):
		new_scene.spawn_party(_pending_spawn_point)

class_name DamageNumbers
extends Node2D

## Spawns floating damage/healing/miss text above tokens during combat.


## Spawn a floating damage number at a world position.
func show_damage(amount: int, world_pos: Vector2, is_crit: bool = false) -> void:
	var text: String = str(amount)
	var color: Color = Color.RED
	var size: int = 16
	if is_crit:
		text = str(amount) + "!"
		color = Color(1.0, 0.8, 0.0)
		size = 22

	_spawn_label(text, world_pos, color, size)


## Spawn a floating heal number.
func show_heal(amount: int, world_pos: Vector2) -> void:
	_spawn_label("+" + str(amount), world_pos, Color(0.2, 1.0, 0.3), 16)


## Spawn a floating "MISS" text.
func show_miss(world_pos: Vector2) -> void:
	_spawn_label("MISS", world_pos, Color(0.7, 0.7, 0.7), 14)


## Spawn a floating status text (e.g., condition name).
func show_status(text: String, world_pos: Vector2) -> void:
	_spawn_label(text, world_pos, Color(1.0, 0.8, 0.2), 12)


func _spawn_label(text: String, world_pos: Vector2, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = world_pos + Vector2(-15, -25)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	add_child(label)

	# Animate: float up and fade out.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

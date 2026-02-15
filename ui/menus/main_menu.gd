extends Control

## Main menu — title screen with "New Game" and "Quit" buttons.
## Set as the project's run/main_scene.

var _creation_screen: Control


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	_build_ui()


func _build_ui() -> void:
	# Full-screen background.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	add_child(bg)

	# Center container for menu content.
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.anchor_left = 0.3
	center.anchor_right = 0.7
	center.anchor_top = 0.2
	center.anchor_bottom = 0.8
	center.offset_left = 0
	center.offset_right = 0
	center.offset_top = 0
	center.offset_bottom = 0
	center.add_theme_constant_override("separation", 20)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	# Title.
	var title := Label.new()
	title.text = "5e Compatible"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	center.add_child(title)

	# Subtitle.
	var subtitle := Label.new()
	subtitle.text = "A D&D 5e SRD Adventure"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	center.add_child(subtitle)

	# Spacer.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	center.add_child(spacer)

	# Button container.
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(btn_box)

	# New Game button.
	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.custom_minimum_size = Vector2(220, 50)
	_style_button(new_game_btn)
	new_game_btn.pressed.connect(_on_new_game)
	btn_box.add_child(new_game_btn)

	# Quit button.
	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(220, 50)
	_style_button(quit_btn)
	quit_btn.pressed.connect(_on_quit)
	btn_box.add_child(quit_btn)


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	normal.border_color = Color(0.6, 0.5, 0.3)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.2, 0.28, 0.95)
	hover.border_color = Color(0.9, 0.8, 0.4)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))


func _on_new_game() -> void:
	if _creation_screen != null:
		return

	GameManager.change_state(GameManager.GameState.CHARACTER_CREATION)

	var scene: PackedScene = load("res://ui/character_creation/character_creation_screen.tscn")
	_creation_screen = scene.instantiate()
	add_child(_creation_screen)

	# Connect to tree_exiting to detect when character creation finishes.
	_creation_screen.tree_exiting.connect(_on_creation_finished)


func _on_creation_finished() -> void:
	_creation_screen = null
	# Character creation calls PartyManager.add_member and queue_free().
	# Transition to the dungeon map.
	TransitionManager.transition_to("res://maps/dungeons/test_dialogue.tscn")


func _on_quit() -> void:
	get_tree().quit()

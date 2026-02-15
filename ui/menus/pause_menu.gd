extends CanvasLayer

## Pause menu overlay with Resume and Quit to Menu buttons.
## Managed by PersistentUI — toggled via Escape key.

var _root: Control
var _panel: PanelContainer


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func open_menu() -> void:
	_root.visible = true


func close_menu() -> void:
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dim overlay.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	_root.add_child(bg)

	# Center panel.
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.3
	_panel.anchor_right = 0.7
	_panel.anchor_top = 0.3
	_panel.anchor_bottom = 0.7
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.6, 0.5, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# Title.
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	vbox.add_child(title)

	# Time display.
	var time_label := Label.new()
	time_label.text = GameManager.get_time_string()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(time_label)

	# Spacer.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Buttons container.
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_box)

	# Resume button.
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(200, 40)
	_style_button(resume_btn)
	resume_btn.pressed.connect(_on_resume)
	btn_box.add_child(resume_btn)

	# Quit to Menu button.
	var quit_btn := Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.custom_minimum_size = Vector2(200, 40)
	_style_button(quit_btn)
	quit_btn.pressed.connect(_on_quit_to_menu)
	btn_box.add_child(quit_btn)

	add_child(_root)


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

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))


func _on_resume() -> void:
	close_menu()
	GameManager.unpause_game()


func _on_quit_to_menu() -> void:
	close_menu()
	# Unpause the tree first so transitions work.
	get_tree().paused = false
	# Reset game state.
	var old_state: int = GameManager.current_state
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	GameManager.previous_state = old_state
	GameManager.state_changed.emit(old_state, GameManager.GameState.MAIN_MENU)
	# Clear party.
	PartyManager.party.clear()
	PartyManager.active_character_index = 0
	# Clear quest state.
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	QuestManager.story_flags.clear()
	# Transition to main menu.
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")

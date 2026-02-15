extends CanvasLayer

## Pause menu overlay with Resume, Save Game, and Quit to Menu buttons.
## Managed by PersistentUI — toggled via Escape key.

var _root: Control
var _panel: PanelContainer
var _btn_box: VBoxContainer
var _slot_picker: VBoxContainer
var _status_label: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func open_menu() -> void:
	_root.visible = true
	# Hide slot picker when reopening.
	if _slot_picker:
		_slot_picker.visible = false
	if _btn_box:
		_btn_box.visible = true
	if _status_label:
		_status_label.text = ""


func close_menu() -> void:
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dim overlay.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = UITheme.COLOR_OVERLAY_DARK
	_root.add_child(bg)

	# Center panel.
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.3
	_panel.anchor_right = 0.7
	_panel.anchor_top = 0.25
	_panel.anchor_bottom = 0.75
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	var style := UIStyler.create_panel_style(UITheme.COLOR_PANEL_BG, UITheme.COLOR_BORDER, 2, 8, 20)
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
	title.add_theme_font_size_override("font_size", UITheme.FONT_HEADING)
	title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	vbox.add_child(title)

	# Time display.
	var time_label := Label.new()
	time_label.text = GameManager.get_time_string()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	time_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	vbox.add_child(time_label)

	# Spacer.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Main buttons container.
	_btn_box = VBoxContainer.new()
	_btn_box.add_theme_constant_override("separation", 10)
	_btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_btn_box)

	# Resume button.
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(200, 40)
	_style_button(resume_btn)
	resume_btn.pressed.connect(_on_resume)
	_btn_box.add_child(resume_btn)

	# Save Game button.
	var save_btn := Button.new()
	save_btn.text = "Save Game"
	save_btn.custom_minimum_size = Vector2(200, 40)
	_style_button(save_btn)
	save_btn.pressed.connect(_on_save_game)
	_btn_box.add_child(save_btn)

	# Quit to Menu button.
	var quit_btn := Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.custom_minimum_size = Vector2(200, 40)
	_style_button(quit_btn)
	quit_btn.pressed.connect(_on_quit_to_menu)
	_btn_box.add_child(quit_btn)

	# Slot picker (hidden by default).
	_slot_picker = VBoxContainer.new()
	_slot_picker.add_theme_constant_override("separation", 8)
	_slot_picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slot_picker.visible = false
	vbox.add_child(_slot_picker)

	var picker_title := Label.new()
	picker_title.text = "Choose Save Slot"
	picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker_title.add_theme_font_size_override("font_size", UITheme.FONT_MEDIUM)
	picker_title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	_slot_picker.add_child(picker_title)

	for i in SaveManager.MAX_SLOTS:
		var slot_btn := Button.new()
		slot_btn.name = "SlotBtn_%d" % i
		slot_btn.custom_minimum_size = Vector2(240, 36)
		_style_button(slot_btn)
		slot_btn.pressed.connect(_on_slot_selected.bind(i))
		_slot_picker.add_child(slot_btn)

	# Back button in slot picker.
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(240, 36)
	_style_button(back_btn)
	back_btn.pressed.connect(_on_slot_back)
	_slot_picker.add_child(back_btn)

	# Status label for save confirmation.
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	_status_label.add_theme_color_override("font_color", UITheme.COLOR_SUCCESS)
	vbox.add_child(_status_label)

	add_child(_root)


func _style_button(btn: Button) -> void:
	UIStyler.style_button(btn)


func _update_slot_labels() -> void:
	for i in SaveManager.MAX_SLOTS:
		var slot_btn: Button = _slot_picker.get_node_or_null("SlotBtn_%d" % i)
		if slot_btn == null:
			continue
		var info: Dictionary = SaveManager.get_save_info(i)
		if info.is_empty():
			slot_btn.text = "Slot %d — Empty" % (i + 1)
		else:
			var name_str: String = info.get("character_name", "Unknown")
			var level: int = info.get("level", 1)
			var time_dict: Dictionary = info.get("game_time", {})
			var time_str: String = "Day %d, %02d:%02d" % [
				time_dict.get("day", 1),
				time_dict.get("hour", 8),
				time_dict.get("minute", 0),
			]
			slot_btn.text = "Slot %d — %s (Lv%d) %s" % [i + 1, name_str, level, time_str]


func _on_resume() -> void:
	close_menu()
	GameManager.unpause_game()


func _on_save_game() -> void:
	# Only allow saving during exploration.
	if GameManager.previous_state != GameManager.GameState.EXPLORING:
		_status_label.text = "Can only save while exploring!"
		_status_label.add_theme_color_override("font_color", UITheme.COLOR_ERROR)
		return

	_btn_box.visible = false
	_slot_picker.visible = true
	_status_label.text = ""
	_update_slot_labels()


func _on_slot_selected(slot: int) -> void:
	# Temporarily unpause so save can read scene state.
	get_tree().paused = false
	var success: bool = SaveManager.save_game(slot)
	get_tree().paused = true

	if success:
		_status_label.add_theme_color_override("font_color", UITheme.COLOR_SUCCESS)
		_status_label.text = "Saved to Slot %d!" % (slot + 1)
	else:
		_status_label.add_theme_color_override("font_color", UITheme.COLOR_ERROR)
		_status_label.text = "Save failed!"

	_slot_picker.visible = false
	_btn_box.visible = true


func _on_slot_back() -> void:
	_slot_picker.visible = false
	_btn_box.visible = true
	_status_label.text = ""


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

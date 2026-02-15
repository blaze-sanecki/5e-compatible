extends Control

## Main menu — title screen with "New Game", "Continue", "Load Game", and "Quit" buttons.
## Set as the project's run/main_scene.

var _creation_screen: Control
var _btn_box: VBoxContainer
var _continue_btn: Button
var _load_btn: Button
var _slot_picker: VBoxContainer
var _status_label: Label


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	_build_ui()


func _build_ui() -> void:
	# Full-screen background.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = UITheme.COLOR_SCREEN_BG
	add_child(bg)

	# Center container for menu content.
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.anchor_left = 0.3
	center.anchor_right = 0.7
	center.anchor_top = 0.15
	center.anchor_bottom = 0.85
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
	title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE)
	title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	center.add_child(title)

	# Subtitle.
	var subtitle := Label.new()
	subtitle.text = "A D&D 5e SRD Adventure"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	subtitle.add_theme_color_override("font_color", UITheme.COLOR_SUBTITLE)
	center.add_child(subtitle)

	# Spacer.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	center.add_child(spacer)

	# Button container.
	_btn_box = VBoxContainer.new()
	_btn_box.add_theme_constant_override("separation", 12)
	_btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_btn_box)

	# Continue button (only visible when saves exist).
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(220, 50)
	_style_button(_continue_btn)
	_continue_btn.pressed.connect(_on_continue)
	_btn_box.add_child(_continue_btn)
	_continue_btn.visible = SaveManager.has_any_save()

	# New Game button.
	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.custom_minimum_size = Vector2(220, 50)
	_style_button(new_game_btn)
	new_game_btn.pressed.connect(_on_new_game)
	_btn_box.add_child(new_game_btn)

	# Load Game button.
	_load_btn = Button.new()
	_load_btn.text = "Load Game"
	_load_btn.custom_minimum_size = Vector2(220, 50)
	_style_button(_load_btn)
	_load_btn.pressed.connect(_on_load_game)
	_btn_box.add_child(_load_btn)
	_load_btn.visible = SaveManager.has_any_save()

	# Quit button.
	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(220, 50)
	_style_button(quit_btn)
	quit_btn.pressed.connect(_on_quit)
	_btn_box.add_child(quit_btn)

	# Slot picker (hidden by default).
	_slot_picker = VBoxContainer.new()
	_slot_picker.add_theme_constant_override("separation", 10)
	_slot_picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slot_picker.visible = false
	center.add_child(_slot_picker)

	var picker_title := Label.new()
	picker_title.text = "Choose Save Slot"
	picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker_title.add_theme_font_size_override("font_size", UITheme.FONT_LARGE)
	picker_title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	_slot_picker.add_child(picker_title)

	for i in SaveManager.MAX_SLOTS:
		var slot_btn := Button.new()
		slot_btn.name = "SlotBtn_%d" % i
		slot_btn.custom_minimum_size = Vector2(280, 44)
		_style_button(slot_btn)
		slot_btn.pressed.connect(_on_load_slot_selected.bind(i))
		_slot_picker.add_child(slot_btn)

	# Back button in slot picker.
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(back_btn)
	back_btn.pressed.connect(_on_load_back)
	_slot_picker.add_child(back_btn)

	# Status label.
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	_status_label.add_theme_color_override("font_color", UITheme.COLOR_ERROR)
	center.add_child(_status_label)


func _style_button(btn: Button) -> void:
	UIStyler.style_button(btn, 18)


func _update_slot_labels() -> void:
	for i in SaveManager.MAX_SLOTS:
		var slot_btn: Button = _slot_picker.get_node_or_null("SlotBtn_%d" % i)
		if slot_btn == null:
			continue
		var info: Dictionary = SaveManager.get_save_info(i)
		if info.is_empty():
			slot_btn.text = "Slot %d — Empty" % (i + 1)
			slot_btn.disabled = true
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
			slot_btn.disabled = false


func _on_continue() -> void:
	var slot: int = SaveManager.get_most_recent_slot()
	if slot < 0:
		_status_label.text = "No saves found!"
		return
	SaveManager.load_game(slot)


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


func _on_load_game() -> void:
	_btn_box.visible = false
	_slot_picker.visible = true
	_status_label.text = ""
	_update_slot_labels()


func _on_load_slot_selected(slot: int) -> void:
	if not SaveManager.has_save(slot):
		_status_label.text = "No save in that slot!"
		return
	_slot_picker.visible = false
	SaveManager.load_game(slot)


func _on_load_back() -> void:
	_slot_picker.visible = false
	_btn_box.visible = true
	_status_label.text = ""


func _on_quit() -> void:
	get_tree().quit()

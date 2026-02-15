extends CanvasLayer

## Rest menu popup — R key during exploration opens short/long rest options.
## Shows results of resting (HP restored, hit dice spent).

var _root: Control
var _panel: PanelContainer
var _content: VBoxContainer
var _result_label: RichTextLabel


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func open_menu() -> void:
	_root.visible = true
	_show_rest_options()


func close_menu() -> void:
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dim overlay.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.4)
	_root.add_child(bg)

	# Panel.
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.25
	_panel.anchor_right = 0.75
	_panel.anchor_top = 0.25
	_panel.anchor_bottom = 0.75
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	_panel.add_theme_stylebox_override("panel", UIStyler.create_panel_style())
	_root.add_child(_panel)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_panel.add_child(_content)

	add_child(_root)


func _show_rest_options() -> void:
	_clear_content()

	# Title.
	var title := Label.new()
	title.text = "Rest"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	_content.add_child(title)

	# Time display.
	var time_label := Label.new()
	time_label.text = GameManager.get_time_string()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	_content.add_child(time_label)

	# Party status.
	for member in PartyManager.party:
		if not member is CharacterData:
			continue
		var character: CharacterData = member as CharacterData
		var status := Label.new()
		var char_name: String = character.character_name if character.character_name else "Hero"
		status.text = "%s — HP: %d/%d — Hit Dice: %d" % [char_name, character.current_hp, character.max_hp, character.hit_dice_remaining]
		status.add_theme_font_size_override("font_size", 13)
		status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		_content.add_child(status)

	# Button container.
	var btn_box := HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(btn_box)

	# Short rest button.
	var short_btn := Button.new()
	short_btn.text = "Short Rest (1 hr)"
	short_btn.custom_minimum_size = Vector2(160, 36)
	_style_button(short_btn)
	short_btn.pressed.connect(_on_short_rest)
	btn_box.add_child(short_btn)

	# Long rest button.
	var long_btn := Button.new()
	long_btn.text = "Long Rest (8 hrs)"
	long_btn.custom_minimum_size = Vector2(160, 36)
	_style_button(long_btn)
	long_btn.pressed.connect(_on_long_rest)
	btn_box.add_child(long_btn)

	# Cancel button.
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	_style_button(cancel_btn)
	cancel_btn.pressed.connect(close_menu)
	btn_box.add_child(cancel_btn)


func _on_short_rest() -> void:
	var results: PackedStringArray = []
	for member in PartyManager.party:
		if not member is CharacterData:
			continue
		var character: CharacterData = member as CharacterData
		var char_name: String = character.character_name if character.character_name else "Hero"
		var healed: int = RestSystem.short_rest(character)
		if healed > 0:
			results.append("%s healed %d HP" % [char_name, healed])
		elif character.hit_dice_remaining <= 0:
			results.append("%s — no hit dice remaining" % char_name)
		else:
			results.append("%s — already at full HP" % char_name)

	GameManager.advance_time(60)
	EventBus.rest_started.emit(&"short")
	EventBus.rest_completed.emit(&"short")

	_show_results("Short Rest Complete", results)


func _on_long_rest() -> void:
	var results: PackedStringArray = []
	for member in PartyManager.party:
		if not member is CharacterData:
			continue
		var character: CharacterData = member as CharacterData
		var char_name: String = character.character_name if character.character_name else "Hero"
		var healed: int = RestSystem.long_rest(character)
		if healed > 0:
			results.append("%s healed %d HP (full)" % [char_name, healed])
		else:
			results.append("%s — already at full HP" % char_name)

	GameManager.advance_time(480)
	EventBus.rest_started.emit(&"long")
	EventBus.rest_completed.emit(&"long")

	_show_results("Long Rest Complete", results)


func _show_results(title_text: String, results: PackedStringArray) -> void:
	_clear_content()

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	_content.add_child(title)

	var time_label := Label.new()
	time_label.text = GameManager.get_time_string()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	_content.add_child(time_label)

	for result in results:
		var line := Label.new()
		line.text = result
		line.add_theme_font_size_override("font_size", 14)
		line.add_theme_color_override("font_color", UITheme.COLOR_QUEST_COMPLETE)
		_content.add_child(line)

	var ok_btn := Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 36)
	_style_button(ok_btn)
	ok_btn.pressed.connect(close_menu)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content.add_child(ok_btn)


func _clear_content() -> void:
	for child in _content.get_children():
		child.queue_free()


func _style_button(btn: Button) -> void:
	UIStyler.style_button(btn, 14, 6)

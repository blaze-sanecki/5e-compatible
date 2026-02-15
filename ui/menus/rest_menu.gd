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

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.6, 0.5, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
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
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	_content.add_child(title)

	# Time display.
	var time_label := Label.new()
	time_label.text = GameManager.get_time_string()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_content.add_child(time_label)

	# Party status.
	for member in PartyManager.party:
		var status := Label.new()
		var char_name: String = str(member.get("character_name")) if member.get("character_name") else "Hero"
		var hp: int = member.get("current_hp") if member.get("current_hp") != null else 0
		var max_hp: int = member.get("max_hp") if member.get("max_hp") != null else 0
		var hd: int = member.get("hit_dice_remaining") if member.get("hit_dice_remaining") != null else 0
		status.text = "%s — HP: %d/%d — Hit Dice: %d" % [char_name, hp, max_hp, hd]
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
	# Collect healing results before the rest.
	var results: PackedStringArray = []
	for member in PartyManager.party:
		if member is CharacterData:
			var healed: int = member.on_short_rest()
			var char_name: String = member.character_name if member.character_name else "Hero"
			if healed > 0:
				results.append("%s healed %d HP" % [char_name, healed])
			else:
				var hd: int = member.hit_dice_remaining
				if hd <= 0:
					results.append("%s — no hit dice remaining" % char_name)
				else:
					results.append("%s — already at full HP" % char_name)

	# Advance time (GameManager.short_rest() also calls on_short_rest,
	# but we already called it, so just advance time and emit signals).
	GameManager.advance_time(60)
	EventBus.rest_started.emit(&"short")
	EventBus.rest_completed.emit(&"short")

	_show_results("Short Rest Complete", results)


func _on_long_rest() -> void:
	var results: PackedStringArray = []
	for member in PartyManager.party:
		if member is CharacterData:
			var old_hp: int = member.current_hp
			member.on_long_rest()
			var healed: int = member.current_hp - old_hp
			var char_name: String = member.character_name if member.character_name else "Hero"
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
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	_content.add_child(title)

	var time_label := Label.new()
	time_label.text = GameManager.get_time_string()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_content.add_child(time_label)

	for result in results:
		var line := Label.new()
		line.text = result
		line.add_theme_font_size_override("font_size", 14)
		line.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
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
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	normal.border_color = Color(0.6, 0.5, 0.3)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.2, 0.28, 0.95)
	hover.border_color = Color(0.9, 0.8, 0.4)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))

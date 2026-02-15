extends HBoxContainer

## Top bar showing initiative order with current turn highlight and HP bars.

var _entries: Array[Dictionary] = []
var _current_index: int = -1


func _ready() -> void:
	EventBus.initiative_rolled.connect(_on_initiative_rolled)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_damaged.connect(_on_character_changed)
	EventBus.character_healed.connect(_on_character_changed_heal)
	EventBus.character_died.connect(_on_character_died)


func _on_initiative_rolled(order: Array) -> void:
	_clear()
	_entries.clear()

	for i in order.size():
		var entry: Dictionary = order[i]
		var panel: PanelContainer = _create_entry_panel(entry, i)
		add_child(panel)
		_entries.append({"panel": panel, "data": entry, "dead": false})


func _on_turn_started(character: Resource) -> void:
	var char_name: String = ""
	if character.get("character_name"):
		char_name = character.character_name
	elif character.get("display_name"):
		char_name = character.display_name

	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var panel: PanelContainer = entry.panel
		if entry.data.get("name", "") == char_name:
			_highlight_panel(panel, true)
			_current_index = i
		else:
			_highlight_panel(panel, false)


func _on_character_changed(_character: Resource, _amount: int, _damage_type: StringName) -> void:
	_refresh_hp_bars()


func _on_character_changed_heal(_character: Resource, _amount: int) -> void:
	_refresh_hp_bars()


func _on_character_died(character: Resource) -> void:
	var char_name: String = ""
	if character.get("character_name"):
		char_name = character.character_name
	elif character.get("display_name"):
		char_name = character.display_name

	for entry in _entries:
		if entry.data.get("name", "") == char_name:
			entry.dead = true
			if entry.panel:
				entry.panel.modulate = UITheme.COLOR_DEAD_MODULATE


func _clear() -> void:
	for child in get_children():
		child.queue_free()


func _create_entry_panel(entry: Dictionary, _index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 50)

	panel.add_theme_stylebox_override("panel", UIStyler.create_panel_style(
		UITheme.COLOR_BUTTON_BG, UITheme.COLOR_INIT_BORDER_INACTIVE, 1, 4, 4))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Name label.
	var name_label := Label.new()
	name_label.text = entry.get("name", "???")
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_TINY)
	var name_color: Color = UITheme.COLOR_PLAYER_NAME if entry.get("is_player", false) else UITheme.COLOR_ENEMY_NAME
	name_label.add_theme_color_override("font_color", name_color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Initiative label.
	var init_label := Label.new()
	init_label.text = "Init: %d" % entry.get("initiative", 0)
	init_label.add_theme_font_size_override("font_size", UITheme.FONT_MICRO)
	init_label.add_theme_color_override("font_color", UITheme.COLOR_INIT_TEXT)
	init_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(init_label)

	return panel


func _highlight_panel(panel: PanelContainer, active: bool) -> void:
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	# Duplicate to avoid shared reference.
	style = style.duplicate() as StyleBoxFlat
	if active:
		style.border_color = UITheme.COLOR_INIT_BORDER_ACTIVE
		style.set_border_width_all(2)
		style.bg_color = UITheme.COLOR_INIT_BG_ACTIVE
	else:
		style.border_color = UITheme.COLOR_INIT_BORDER_INACTIVE
		style.set_border_width_all(1)
		style.bg_color = UITheme.COLOR_BUTTON_BG
	panel.add_theme_stylebox_override("panel", style)


func _refresh_hp_bars() -> void:
	# HP bars are tracked externally; this is a simple display.
	pass

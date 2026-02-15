extends HBoxContainer

## Bottom bar showing available combat actions for the current player's turn.
## Buttons: Attack, Use Item, Dash, Disengage, Dodge, Hide, End Turn.

signal action_selected(action_name: StringName)

var _buttons: Dictionary = {}
var _combat_manager: CombatManager = null
var _item_popup: PanelContainer = null


func _ready() -> void:
	_create_buttons()
	visible = false

	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)


func set_combat_manager(mgr: CombatManager) -> void:
	_combat_manager = mgr


func _create_buttons() -> void:
	var actions: Array[Array] = [
		["Attack", &"attack", UITheme.COLOR_ACTION_ATTACK, "A"],
		["Use Item", &"use_item", UITheme.COLOR_ACTION_ITEM, "I"],
		["Dash", &"dash", UITheme.COLOR_ACTION_DASH, "D"],
		["Disengage", &"disengage", UITheme.COLOR_ACTION_DISENGAGE, "G"],
		["Dodge", &"dodge", UITheme.COLOR_ACTION_DODGE, "O"],
		["Hide", &"hide", UITheme.COLOR_ACTION_HIDE, "H"],
		["End Turn", &"end_turn", UITheme.COLOR_ACTION_END_TURN, "Enter"],
	]

	for action_def in actions:
		var btn := Button.new()
		btn.text = "%s [%s]" % [action_def[0], action_def[3]]
		btn.custom_minimum_size = Vector2(100, 36)

		var style := StyleBoxFlat.new()
		style.bg_color = (action_def[2] as Color).darkened(0.5)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate() as StyleBoxFlat
		hover_style.bg_color = action_def[2] as Color
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := style.duplicate() as StyleBoxFlat
		pressed_style.bg_color = (action_def[2] as Color).darkened(0.3)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var action_id: StringName = action_def[1]
		btn.pressed.connect(func() -> void: _on_action_pressed(action_id))

		add_child(btn)
		_buttons[action_id] = btn


func _on_action_pressed(action_name: StringName) -> void:
	if _combat_manager == null:
		action_selected.emit(action_name)
		return

	match action_name:
		&"attack":
			pass  # Handled by combat_hud -> combat_grid_controller
		&"use_item":
			_show_item_picker()
			return  # Don't emit action_selected yet.
		&"dash":
			_combat_manager.player_dash()
			_update_button_states()
		&"disengage":
			_combat_manager.player_disengage()
			_update_button_states()
		&"dodge":
			_combat_manager.player_dodge()
			_update_button_states()
		&"hide":
			_combat_manager.player_hide()
			_update_button_states()
		&"end_turn":
			_combat_manager.end_current_turn()

	# Emit after the action executes so listeners see updated state.
	action_selected.emit(action_name)


func _on_combat_started() -> void:
	visible = true


func _on_combat_ended() -> void:
	visible = false
	_close_item_picker()


func _on_turn_started(_character: Resource) -> void:
	_close_item_picker()
	_update_button_states()


func _on_turn_ended(_character: Resource) -> void:
	_close_item_picker()


func _update_button_states() -> void:
	if _combat_manager == null:
		return
	var c: CombatantData = _combat_manager.current_combatant
	if c == null or not c.is_player():
		_set_all_disabled(true)
		return

	_buttons[&"attack"].disabled = not _combat_manager.action_system.can_attack(c)
	_buttons[&"use_item"].disabled = not _combat_manager.action_system.can_use_item(c)
	_buttons[&"dash"].disabled = not _combat_manager.action_system.can_dash(c)
	_buttons[&"disengage"].disabled = not _combat_manager.action_system.can_disengage(c)
	_buttons[&"dodge"].disabled = not _combat_manager.action_system.can_dodge(c)
	_buttons[&"hide"].disabled = not _combat_manager.action_system.can_hide(c)
	_buttons[&"end_turn"].disabled = false


func _set_all_disabled(disabled: bool) -> void:
	for btn in _buttons.values():
		btn.disabled = disabled


# ---------------------------------------------------------------------------
# Item picker popup
# ---------------------------------------------------------------------------

func _show_item_picker() -> void:
	if _combat_manager == null or _combat_manager.current_combatant == null:
		return

	_close_item_picker()

	var combatant: CombatantData = _combat_manager.current_combatant
	var items: Array[ItemData] = _combat_manager.action_system.get_consumable_items(combatant)
	if items.is_empty():
		return

	# Build a popup panel above the action bar.
	_item_popup = PanelContainer.new()
	_item_popup.name = "ItemPickerPopup"

	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = UITheme.COLOR_ITEM_POPUP_BG
	popup_style.border_color = UITheme.COLOR_ITEM_POPUP_BORDER
	popup_style.set_border_width_all(2)
	popup_style.set_corner_radius_all(6)
	popup_style.set_content_margin_all(10)
	_item_popup.add_theme_stylebox_override("panel", popup_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_item_popup.add_child(vbox)

	var title := Label.new()
	title.text = "Use Item (Action)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	title.add_theme_color_override("font_color", UITheme.COLOR_ITEM_POPUP_BORDER)
	vbox.add_child(title)

	# Count quantities for display.
	var character: CharacterData = combatant.source as CharacterData
	for item in items:
		var qty: int = _get_item_quantity(character, item)
		var item_btn := Button.new()
		item_btn.text = "%s (x%d)" % [item.display_name, qty]
		item_btn.custom_minimum_size = Vector2(180, 30)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = UITheme.COLOR_ITEM_BTN_BG
		btn_style.border_color = Color(0.3, 0.8, 0.6, 0.5)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(4)
		item_btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover := btn_style.duplicate() as StyleBoxFlat
		btn_hover.bg_color = UITheme.COLOR_ITEM_BTN_HOVER
		btn_hover.border_color = UITheme.COLOR_ITEM_POPUP_BORDER
		item_btn.add_theme_stylebox_override("hover", btn_hover)

		item_btn.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		item_btn.add_theme_color_override("font_color", UITheme.COLOR_ITEM_TEXT)

		var captured_item: ItemData = item
		item_btn.pressed.connect(func() -> void: _on_item_selected(captured_item))
		vbox.add_child(item_btn)

	# Cancel button.
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(180, 28)
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = UITheme.COLOR_CANCEL_BG
	cancel_style.set_corner_radius_all(4)
	cancel_style.set_content_margin_all(4)
	cancel_btn.add_theme_stylebox_override("normal", cancel_style)
	cancel_btn.add_theme_font_size_override("font_size", UITheme.FONT_DETAIL)
	cancel_btn.add_theme_color_override("font_color", UITheme.COLOR_CANCEL_TEXT)
	cancel_btn.pressed.connect(_close_item_picker)
	vbox.add_child(cancel_btn)

	# Position above the Use Item button.
	var use_btn: Button = _buttons[&"use_item"]
	_item_popup.position = Vector2(use_btn.global_position.x, use_btn.global_position.y - 10)

	# Add to a high-layer parent so it renders above everything.
	var canvas: CanvasLayer = get_parent() as CanvasLayer
	if canvas:
		canvas.add_child(_item_popup)
		# Adjust position after the popup knows its size.
		await get_tree().process_frame
		_item_popup.position.y -= _item_popup.size.y
	else:
		add_child(_item_popup)


func _on_item_selected(item: ItemData) -> void:
	_close_item_picker()
	if _combat_manager == null:
		return
	_combat_manager.player_use_item(item)
	_update_button_states()
	action_selected.emit(&"use_item")


func _close_item_picker() -> void:
	if _item_popup and is_instance_valid(_item_popup):
		_item_popup.queue_free()
		_item_popup = null


func _get_item_quantity(character: CharacterData, item: ItemData) -> int:
	for entry in character.inventory:
		if entry is InventoryEntry and entry.item == item:
			return entry.quantity
	return 1

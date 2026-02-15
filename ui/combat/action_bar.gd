extends HBoxContainer

## Bottom bar showing available combat actions for the current player's turn.
## Buttons: Attack, Dash, Disengage, Dodge, Hide, End Turn.

signal action_selected(action_name: StringName)

var _buttons: Dictionary = {}
var _combat_manager: CombatManager = null


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
		["Attack", &"attack", Color(0.9, 0.3, 0.2), "A"],
		["Dash", &"dash", Color(0.2, 0.7, 0.9), "D"],
		["Disengage", &"disengage", Color(0.5, 0.8, 0.3), "G"],
		["Dodge", &"dodge", Color(0.8, 0.7, 0.2), "O"],
		["Hide", &"hide", Color(0.6, 0.4, 0.8), "H"],
		["End Turn", &"end_turn", Color(0.5, 0.5, 0.5), "Enter"],
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


func _on_turn_started(_character: Resource) -> void:
	_update_button_states()


func _on_turn_ended(_character: Resource) -> void:
	pass


func _update_button_states() -> void:
	if _combat_manager == null:
		return
	var c: CombatantData = _combat_manager.current_combatant
	if c == null or not c.is_player():
		_set_all_disabled(true)
		return

	_buttons[&"attack"].disabled = not _combat_manager.action_system.can_attack(c)
	_buttons[&"dash"].disabled = not _combat_manager.action_system.can_dash(c)
	_buttons[&"disengage"].disabled = not _combat_manager.action_system.can_disengage(c)
	_buttons[&"dodge"].disabled = not _combat_manager.action_system.can_dodge(c)
	_buttons[&"hide"].disabled = not _combat_manager.action_system.can_hide(c)
	_buttons[&"end_turn"].disabled = false


func _set_all_disabled(disabled: bool) -> void:
	for btn in _buttons.values():
		btn.disabled = disabled

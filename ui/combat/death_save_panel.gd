extends PanelContainer

## Modal panel displayed when a player character is at 0 HP.
## Shows death save successes/failures and a roll button.

signal death_save_requested()

var _success_labels: Array[Label] = []
var _failure_labels: Array[Label] = []
var _roll_button: Button
var _result_label: Label
var _name_label: Label

var _combat_manager: CombatManager = null


func _ready() -> void:
	visible = false
	_build_ui()


func set_combat_manager(mgr: CombatManager) -> void:
	_combat_manager = mgr


func show_for_combatant(combatant: CombatantData) -> void:
	if not combatant.is_player() or combatant.current_hp > 0:
		visible = false
		return

	visible = true
	_name_label.text = combatant.display_name + " - Death Saves"
	_update_circles(combatant)
	_result_label.text = ""
	_roll_button.disabled = false


func hide_panel() -> void:
	visible = false


func _build_ui() -> void:
	custom_minimum_size = Vector2(280, 160)

	add_theme_stylebox_override("panel", UIStyler.create_panel_style(
		UITheme.COLOR_DEATH_PANEL_BG, UITheme.COLOR_DEATH_PANEL_BORDER, 2, 8, 12))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Title
	_name_label = Label.new()
	_name_label.text = "Death Saves"
	_name_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	_name_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_NAME)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_name_label)

	# Successes row
	var success_row := HBoxContainer.new()
	success_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(success_row)
	var s_label := Label.new()
	s_label.text = "Successes: "
	s_label.add_theme_font_size_override("font_size", UITheme.FONT_DETAIL)
	s_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_SUCCESS)
	success_row.add_child(s_label)
	for i in 3:
		var circle := Label.new()
		circle.text = "O"
		circle.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		circle.add_theme_color_override("font_color", UITheme.COLOR_DEATH_INACTIVE)
		success_row.add_child(circle)
		_success_labels.append(circle)

	# Failures row
	var failure_row := HBoxContainer.new()
	failure_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(failure_row)
	var f_label := Label.new()
	f_label.text = "Failures:  "
	f_label.add_theme_font_size_override("font_size", UITheme.FONT_DETAIL)
	f_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_FAILURE)
	failure_row.add_child(f_label)
	for i in 3:
		var circle := Label.new()
		circle.text = "X"
		circle.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		circle.add_theme_color_override("font_color", UITheme.COLOR_DEATH_INACTIVE)
		failure_row.add_child(circle)
		_failure_labels.append(circle)

	# Roll button
	_roll_button = Button.new()
	_roll_button.text = "Roll Death Save"
	_roll_button.custom_minimum_size = Vector2(140, 32)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = UITheme.COLOR_DEATH_SAVE_BTN
	btn_style.set_corner_radius_all(4)
	_roll_button.add_theme_stylebox_override("normal", btn_style)
	_roll_button.pressed.connect(_on_roll_pressed)
	vbox.add_child(_roll_button)

	# Result label
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", UITheme.FONT_DETAIL)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)


func _on_roll_pressed() -> void:
	if _combat_manager == null:
		death_save_requested.emit()
		return

	var result: Dictionary = _combat_manager.player_death_save()
	if result.is_empty():
		return

	var combatant: CombatantData = _combat_manager.current_combatant
	_update_circles(combatant)

	if result.get("revived", false):
		_result_label.text = "Natural 20! Regained 1 HP!"
		_result_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_BRIGHT_SUCCESS)
		_roll_button.disabled = true
		await get_tree().create_timer(1.5).timeout
		hide_panel()
		_combat_manager.end_current_turn()
	elif result.get("died", false):
		_result_label.text = "Failed... Died."
		_result_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_BRIGHT_FAILURE)
		_roll_button.disabled = true
		await get_tree().create_timer(1.5).timeout
		hide_panel()
		_combat_manager.end_current_turn()
	elif result.get("stabilized", false):
		_result_label.text = "Stabilized!"
		_result_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_STABILIZED)
		_roll_button.disabled = true
		await get_tree().create_timer(1.5).timeout
		hide_panel()
		_combat_manager.end_current_turn()
	elif result.get("success", false):
		_result_label.text = "Success (rolled %d)" % result.get("natural_roll", 0)
		_result_label.add_theme_color_override("font_color", UITheme.COLOR_DEATH_STABILIZED)
	else:
		_result_label.text = "Failure (rolled %d)" % result.get("natural_roll", 0)
		_result_label.add_theme_color_override("font_color", UITheme.COLOR_ERROR)


func _update_circles(combatant: CombatantData) -> void:
	for i in 3:
		if i < combatant.death_save_successes:
			_success_labels[i].add_theme_color_override("font_color", UITheme.COLOR_DEATH_BRIGHT_SUCCESS)
		else:
			_success_labels[i].add_theme_color_override("font_color", UITheme.COLOR_DEATH_INACTIVE)

		if i < combatant.death_save_failures:
			_failure_labels[i].add_theme_color_override("font_color", UITheme.COLOR_DEATH_FAILURE)
		else:
			_failure_labels[i].add_theme_color_override("font_color", UITheme.COLOR_DEATH_INACTIVE)

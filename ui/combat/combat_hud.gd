extends CanvasLayer

## Container for all combat UI elements. Shown during combat, hidden otherwise.
## Wires up the initiative tracker, action bar, combat log, and death save panel.

var initiative_tracker: HBoxContainer
var action_bar: HBoxContainer
var combat_log: PanelContainer
var death_save_panel: PanelContainer

var _combat_manager: CombatManager = null
var _combat_grid_controller: CombatGridController = null


func _ready() -> void:
	layer = 10  # Above the game.
	visible = false

	# Create sub-UI nodes.
	initiative_tracker = preload("res://ui/combat/initiative_tracker.tscn").instantiate()
	add_child(initiative_tracker)

	action_bar = preload("res://ui/combat/action_bar.tscn").instantiate()
	add_child(action_bar)

	combat_log = preload("res://ui/combat/combat_log.tscn").instantiate()
	add_child(combat_log)

	death_save_panel = preload("res://ui/combat/death_save_panel.tscn").instantiate()
	add_child(death_save_panel)

	# Wire up action bar signals.
	if action_bar.has_signal("action_selected"):
		action_bar.action_selected.connect(_on_action_selected)

	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)


func setup(combat_mgr: CombatManager, grid_ctrl: CombatGridController) -> void:
	_combat_manager = combat_mgr
	_combat_grid_controller = grid_ctrl

	if action_bar.has_method("set_combat_manager"):
		action_bar.set_combat_manager(combat_mgr)
	if death_save_panel.has_method("set_combat_manager"):
		death_save_panel.set_combat_manager(combat_mgr)

	# Connect keyboard shortcuts from the grid controller.
	if grid_ctrl.has_signal("action_requested"):
		grid_ctrl.action_requested.connect(_on_action_requested)

	# Connect player turn for death save panel.
	combat_mgr.player_turn_started.connect(_on_player_turn_started)


func _on_combat_started() -> void:
	visible = true


func _on_combat_ended() -> void:
	visible = false
	if death_save_panel.has_method("hide_panel"):
		death_save_panel.hide_panel()


func _on_player_turn_started(combatant: CombatantData) -> void:
	if combatant.is_unconscious():
		if death_save_panel.has_method("show_for_combatant"):
			death_save_panel.show_for_combatant(combatant)
	else:
		if death_save_panel.has_method("hide_panel"):
			death_save_panel.hide_panel()


## Handle keyboard shortcuts from combat_grid_controller.
func _on_action_requested(action_name: StringName) -> void:
	if _combat_manager == null:
		return
	# Route through the action bar so it executes the action and updates buttons.
	if action_bar.has_method("_on_action_pressed"):
		action_bar._on_action_pressed(action_name)


func _on_action_selected(action_name: StringName) -> void:
	if _combat_grid_controller == null:
		return

	match action_name:
		&"attack":
			_combat_grid_controller.set_mode_attack()
		&"end_turn":
			if _combat_manager:
				_combat_manager.end_current_turn()
		&"use_item":
			# Handled by the action bar's item picker popup.
			pass
		&"dash", &"disengage", &"dodge", &"hide":
			# These are executed by the action bar directly.
			# Switch back to move mode and refresh overlay (e.g., Dash adds movement).
			_combat_grid_controller.set_mode_move()

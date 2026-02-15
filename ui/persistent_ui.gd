extends CanvasLayer

## Always-present UI layer that hosts DialoguePanel, QuestJournal,
## QuestNotification, ExplorationHUD, and PauseMenu across all scenes.
## Registered as an autoload so these nodes survive scene transitions.

var dialogue_panel: DialoguePanel
var quest_journal: QuestJournal
var quest_notification: QuestNotification
var exploration_hud: Node  # Loaded from scene.
var pause_menu: Node
var rest_menu: Node

## Whether the pause menu is currently open.
var _pause_open: bool = false
## Whether the rest menu is currently open.
var _rest_open: bool = false
## Whether the inventory screen is currently open.
var _inventory_open: bool = false
## Active inventory screen instance.
var _inventory_instance: Control = null


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	dialogue_panel = DialoguePanel.new()
	add_child(dialogue_panel)

	quest_journal = QuestJournal.new()
	add_child(quest_journal)

	quest_notification = QuestNotification.new()
	add_child(quest_notification)

	# Exploration HUD (loaded from scene file).
	var hud_scene: PackedScene = load("res://ui/hud/exploration_hud.tscn")
	if hud_scene:
		exploration_hud = hud_scene.instantiate()
		add_child(exploration_hud)

	# Pause menu.
	var pm_script: GDScript = load("res://ui/menus/pause_menu.gd")
	if pm_script:
		pause_menu = pm_script.new()
		add_child(pause_menu)

	# Rest menu.
	var rm_script: GDScript = load("res://ui/menus/rest_menu.gd")
	if rm_script:
		rest_menu = rm_script.new()
		add_child(rest_menu)

	GameManager.state_changed.connect(_on_game_state_changed)
	_update_hud_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			# Close rest menu with Escape if open.
			if _rest_open and rest_menu != null:
				rest_menu.close_menu()
				_rest_open = false
				get_viewport().set_input_as_handled()
				return
			_toggle_pause()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_R:
			_toggle_rest()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_I:
			_toggle_inventory()
			get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if pause_menu == null:
		return

	# Don't pause on main menu or character creation.
	var state: int = GameManager.current_state
	if state == GameManager.GameState.MAIN_MENU or state == GameManager.GameState.CHARACTER_CREATION:
		return

	if GameManager.current_state == GameManager.GameState.PAUSED:
		if pause_menu.has_method("close_menu"):
			pause_menu.close_menu()
		GameManager.unpause_game()
		_pause_open = false
	else:
		GameManager.pause_game()
		if pause_menu.has_method("open_menu"):
			pause_menu.open_menu()
		_pause_open = true


func _toggle_inventory() -> void:
	if not GameManager.is_exploring():
		return
	if _inventory_open and _inventory_instance != null:
		_inventory_instance.queue_free()
		_inventory_instance = null
		_inventory_open = false
		GameManager.change_state(GameManager.GameState.EXPLORING)
	else:
		if PartyManager.get_active_character() == null:
			return
		var scene: PackedScene = load("res://ui/inventory/inventory_screen.tscn")
		if scene == null:
			return
		_inventory_instance = scene.instantiate()
		# Add to the scene tree root so it renders on top.
		get_tree().current_scene.add_child(_inventory_instance)
		_inventory_open = true
		GameManager.change_state(GameManager.GameState.INVENTORY)
		# Detect when it closes itself (via Close button).
		_inventory_instance.tree_exiting.connect(func() -> void:
			_inventory_open = false
			_inventory_instance = null
		)


func _toggle_rest() -> void:
	if rest_menu == null:
		return
	if not GameManager.is_exploring():
		return
	if _rest_open:
		rest_menu.close_menu()
		_rest_open = false
	else:
		rest_menu.open_menu()
		_rest_open = true


func _on_game_state_changed(_old: int, _new: int) -> void:
	_update_hud_visibility()


func _update_hud_visibility() -> void:
	if exploration_hud == null:
		return

	var state: int = GameManager.current_state
	var show: bool = (
		state == GameManager.GameState.EXPLORING
		or state == GameManager.GameState.DIALOGUE
	)
	exploration_hud.visible = show

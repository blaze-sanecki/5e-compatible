extends PanelContainer

## Side panel showing a scrollable log of combat events.
## Connects to EventBus signals and formats messages with BBCode.

var _rich_label: RichTextLabel


func _ready() -> void:
	# Style the panel.
	add_theme_stylebox_override("panel", UIStyler.create_panel_style(
		Color(0.08, 0.08, 0.12, 0.85), Color(0.3, 0.3, 0.4), 1, 4, 6))

	# Create the RichTextLabel.
	_rich_label = RichTextLabel.new()
	_rich_label.name = "LogText"
	_rich_label.bbcode_enabled = true
	_rich_label.scroll_following = true
	_rich_label.fit_content = false
	_rich_label.add_theme_font_size_override("normal_font_size", 11)
	add_child(_rich_label)

	# Connect signals.
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_damaged.connect(_on_character_damaged)
	EventBus.character_healed.connect(_on_character_healed)
	EventBus.character_died.connect(_on_character_died)
	EventBus.action_performed.connect(_on_action_performed)
	EventBus.condition_applied.connect(_on_condition_applied)
	EventBus.condition_removed.connect(_on_condition_removed)
	EventBus.death_save_made.connect(_on_death_save_made)
	EventBus.initiative_rolled.connect(_on_initiative_rolled)

	visible = false


func _on_combat_started() -> void:
	visible = true
	_rich_label.clear()
	_log("[color=yellow]--- Combat Begins ---[/color]")


func _on_combat_ended() -> void:
	_log("[color=yellow]--- Combat Ends ---[/color]")


func _on_turn_started(character: Resource) -> void:
	var name_str: String = _get_name(character)
	_log("[color=cyan]%s's turn[/color]" % name_str)


func _on_character_damaged(character: Resource, amount: int, damage_type: StringName) -> void:
	var name_str: String = _get_name(character)
	_log("[color=red]%s takes %d %s damage[/color]" % [name_str, amount, damage_type])


func _on_character_healed(character: Resource, amount: int) -> void:
	var name_str: String = _get_name(character)
	_log("[color=green]%s heals %d HP[/color]" % [name_str, amount])


func _on_character_died(character: Resource) -> void:
	var name_str: String = _get_name(character)
	_log("[color=gray]%s has been defeated![/color]" % name_str)


func _on_action_performed(character: Resource, action: Dictionary) -> void:
	var name_str: String = _get_name(character)
	var action_type: String = action.get("type", "")

	match action_type:
		"attack":
			var weapon: String = action.get("weapon", "")
			var hit: bool = action.get("hit", false)
			var damage: int = action.get("damage", 0)
			if hit:
				_log("%s attacks with %s — [color=red]%d damage[/color]" % [name_str, weapon, damage])
			else:
				_log("%s attacks with %s — [color=gray]miss[/color]" % [name_str, weapon])
		"dash":
			_log("%s dashes" % name_str)
		"disengage":
			_log("%s disengages" % name_str)
		"dodge":
			_log("%s dodges" % name_str)
		"hide":
			var stealth: int = action.get("stealth_roll", 0)
			_log("%s hides (Stealth: %d)" % [name_str, stealth])
		"help":
			_log("%s helps an ally" % name_str)


func _on_condition_applied(character: Resource, condition: StringName) -> void:
	var name_str: String = _get_name(character)
	_log("[color=orange]%s is now %s[/color]" % [name_str, condition])


func _on_condition_removed(character: Resource, condition: StringName) -> void:
	var name_str: String = _get_name(character)
	_log("[color=green]%s is no longer %s[/color]" % [name_str, condition])


func _on_death_save_made(character: Resource, result: Dictionary) -> void:
	var name_str: String = _get_name(character)
	if result.get("revived", false):
		_log("[color=green]%s rolls a natural 20 — regains 1 HP![/color]" % name_str)
	elif result.get("died", false):
		_log("[color=gray]%s fails their death save... and dies.[/color]" % name_str)
	elif result.get("stabilized", false):
		_log("[color=green]%s stabilizes![/color]" % name_str)
	elif result.get("success", false):
		_log("%s death save: [color=green]Success[/color] (rolled %d)" % [name_str, result.get("natural_roll", 0)])
	else:
		_log("%s death save: [color=red]Failure[/color] (rolled %d)" % [name_str, result.get("natural_roll", 0)])


func _on_initiative_rolled(order: Array) -> void:
	_log("[color=yellow]Initiative:[/color]")
	for entry in order:
		var name_str: String = entry.get("name", "???")
		var init_val: int = entry.get("initiative", 0)
		_log("  %s: %d" % [name_str, init_val])


func _log(text: String) -> void:
	_rich_label.append_text(text + "\n")


func _get_name(character: Resource) -> String:
	if character.get("character_name"):
		return character.character_name
	if character.get("display_name"):
		return character.display_name
	return "Unknown"

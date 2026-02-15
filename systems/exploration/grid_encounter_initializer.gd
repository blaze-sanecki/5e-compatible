class_name GridEncounterInitializer
extends RefCounted

## Handles combat encounter setup, teardown, and trigger wiring
## for GridDungeonController.

var _controller: Node2D


func _init(controller: Node2D) -> void:
	_controller = controller


# ---------------------------------------------------------------------------
# Trigger setup
# ---------------------------------------------------------------------------

## Position encounter triggers at their assigned cells.
func setup_triggers() -> void:
	var triggers_parent: Node = _controller.get_node_or_null("EncounterTriggers")
	if triggers_parent == null:
		return
	for child in triggers_parent.get_children():
		if child is CombatEncounterTrigger:
			var trigger: CombatEncounterTrigger = child as CombatEncounterTrigger
			if trigger.trigger_cell == Vector2i.ZERO:
				var encounter: CombatEncounterData = DataRegistry.get_encounter(trigger.encounter_id)
				if encounter and not encounter.monster_spawns.is_empty():
					trigger.trigger_cell = encounter.monster_spawns[0].cell
				else:
					trigger.trigger_cell = Vector2i(10, 3)
			if _controller.floor_layer:
				trigger.position = _controller.floor_layer.map_to_local(trigger.trigger_cell)


## Check all encounter triggers after movement to a cell.
func check_triggers(cell: Vector2i) -> void:
	if GameManager.is_in_combat():
		return
	var triggers_parent: Node = _controller.get_node_or_null("EncounterTriggers")
	if triggers_parent == null:
		return
	for child in triggers_parent.get_children():
		if child is CombatEncounterTrigger:
			if child.check_trigger(cell, _controller):
				return  # One encounter at a time.


# ---------------------------------------------------------------------------
# Encounter lifecycle
# ---------------------------------------------------------------------------

## Start a combat encounter. Creates CombatManager and wires everything up.
func start_encounter(encounter: CombatEncounterData) -> void:
	var tm: GridTokenManager = _controller.token_manager

	# Spawn monster tokens.
	var spawn_results: Array[Dictionary] = tm.spawn_monsters(encounter)

	# Create player combatants from character tokens + states.
	var player_combatants: Array[CombatantData] = []
	for i in tm.character_tokens.size():
		var ct: CharacterToken = tm.character_tokens[i]
		var cs: GridEntityState = tm.character_states[i] if i < tm.character_states.size() else null
		if ct.character_data == null:
			var placeholder := CharacterData.new()
			placeholder.character_name = "Hero"
			placeholder.level = 1
			placeholder.max_hp = 12
			placeholder.current_hp = 12
			placeholder.speed = 30
			placeholder.ability_scores = AbilityScores.new()
			placeholder.ability_scores.strength = 14
			placeholder.ability_scores.dexterity = 12
			placeholder.ability_scores.constitution = 13
			ct.character_data = placeholder
		var combatant: CombatantData = CombatantData.from_character(ct.character_data)
		combatant.cell = cs.current_cell if cs else Vector2i.ZERO
		combatant.token = ct
		player_combatants.append(combatant)

	# Create monster combatants.
	var monster_combatants: Array[CombatantData] = []
	for entry in spawn_results:
		var combatant: CombatantData = CombatantData.from_monster(entry.data)
		combatant.cell = entry.cell
		combatant.token = entry.token
		monster_combatants.append(combatant)

	# Create CombatManager.
	var combat_mgr := CombatManager.new()
	combat_mgr.name = "CombatManager"
	combat_mgr.floor_layer = _controller.floor_layer
	combat_mgr.wall_layer = _controller.wall_layer
	combat_mgr.edge_walls = _controller.edge_walls
	_controller.add_child(combat_mgr)

	# Create Monster AI.
	var ai := MonsterAI.new()
	combat_mgr.monster_ai = ai

	# Create targeting overlay.
	var overlay := TargetingOverlay.new()
	overlay.name = "TargetingOverlay"
	overlay.z_index = 5
	overlay.setup(_controller.floor_layer)
	_controller.add_child(overlay)

	# Create damage numbers display.
	var dmg_numbers := DamageNumbers.new()
	dmg_numbers.name = "DamageNumbers"
	dmg_numbers.z_index = 20
	_controller.add_child(dmg_numbers)

	# Create CombatGridController.
	var cgc := CombatGridController.new()
	cgc.combat_manager = combat_mgr
	cgc.floor_layer = _controller.floor_layer
	cgc.wall_layer = _controller.wall_layer
	cgc.edge_walls = _controller.edge_walls
	cgc.pathfinder = _controller.pathfinder
	cgc.targeting_overlay = overlay

	# Create and set up CombatHUD.
	var hud: CanvasLayer = preload("res://ui/combat/combat_hud.tscn").instantiate()
	_controller.add_child(hud)
	if hud.has_method("setup"):
		hud.setup(combat_mgr, cgc)

	# Store references on the controller.
	_controller.combat_manager = combat_mgr
	_controller.combat_grid_controller = cgc

	# Connect combat end.
	combat_mgr.combat_finished.connect(_on_combat_finished)
	combat_mgr.player_turn_started.connect(_on_player_turn_started)

	# Start combat.
	combat_mgr.start_combat(player_combatants, monster_combatants, encounter)


func _on_combat_finished(players_won: bool) -> void:
	if _controller.combat_grid_controller:
		_controller.combat_grid_controller.clear_overlays()
		_controller.combat_grid_controller = null

	var combat_mgr: CombatManager = _controller.combat_manager
	var tm: GridTokenManager = _controller.token_manager

	# Award XP if players won.
	if players_won and combat_mgr:
		var rewards: Dictionary = CombatRewards.award_xp(
			combat_mgr.combatants, combat_mgr.encounter_data
		)
		if rewards.get("total_xp", 0) > 0:
			print("Combat won! XP awarded: %d total (%d each)" % [
				rewards.total_xp, rewards.per_character
			])
			for name_str in rewards.get("level_ups", []):
				print("  %s leveled up!" % name_str)
		else:
			print("Combat won!")
	elif not players_won:
		print("Combat lost!")

	# Sync player positions from combat back to exploration states.
	if combat_mgr:
		for combatant in combat_mgr.combatants:
			if combatant.is_player() and combatant.token:
				var idx: int = tm.character_tokens.find(combatant.token)
				if idx >= 0 and idx < tm.character_states.size():
					tm.character_states[idx].teleport(combatant.cell)

	# Clean up dead monster tokens.
	tm.remove_monsters()

	# Clean up overlay and damage numbers.
	var overlay: Node = _controller.get_node_or_null("TargetingOverlay")
	if overlay:
		overlay.queue_free()
	var dmg_numbers: Node = _controller.get_node_or_null("DamageNumbers")
	if dmg_numbers:
		dmg_numbers.queue_free()

	# Clean up CombatHUD.
	for child in _controller.get_children():
		if child is CanvasLayer and child.name == "CombatHUD":
			child.queue_free()

	# Clean up CombatManager.
	if combat_mgr:
		combat_mgr.queue_free()
		_controller.combat_manager = null


func _on_player_turn_started(combatant: CombatantData) -> void:
	if _controller.combat_grid_controller:
		_controller.combat_grid_controller.set_mode_move()

	# Focus camera on the active player's token.
	if combatant.token and combatant.is_player() and _controller.camera:
		var tween: Tween = _controller.create_tween()
		tween.tween_property(
			_controller.camera, "position",
			(combatant.token as Node2D).position, 0.3
		).set_ease(Tween.EASE_OUT)

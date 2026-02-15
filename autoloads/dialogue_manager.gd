## Dialogue state machine and event executor.
##
## Registered as an autoload singleton. Traverses DialogueTree resources,
## evaluates conditions on choices, rolls skill checks, and executes events
## such as starting quests, giving items, and setting story flags.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when a new dialogue node becomes active (UI should update).
signal node_changed(node: DialogueNode)

## Emitted when the dialogue tree has ended.
signal dialogue_finished()

## Emitted when a skill check is resolved during dialogue.
signal skill_check_resolved(skill: StringName, dc: int, roll_total: int, success: bool)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The dialogue tree currently being traversed, or null.
var current_tree: DialogueTree = null

## The dialogue node currently being displayed, or null.
var current_node: DialogueNode = null

## Whether a dialogue is in progress.
var is_active: bool = false

## Encounter id queued to start after dialogue ends (set by "start_combat" event).
var _pending_encounter_id: StringName = &""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Start traversing a dialogue tree by its DataRegistry id.
func start_dialogue(tree_id: StringName) -> void:
	var tree: DialogueTree = DataRegistry.get_dialogue(tree_id)
	if tree == null:
		push_warning("DialogueManager: Unknown dialogue tree '%s'" % tree_id)
		return

	current_tree = tree
	is_active = true

	GameManager.change_state(GameManager.GameState.DIALOGUE)
	EventBus.dialogue_started.emit(tree.npc_name)

	# Navigate to the start node.
	var start: DialogueNode = tree.get_node_by_id(tree.start_node_id) as DialogueNode
	if start == null:
		push_warning("DialogueManager: Start node '%s' not found in tree '%s'" % [tree.start_node_id, tree_id])
		end_dialogue()
		return

	_set_current_node(start)


## Advance to the next node when the current node has no choices.
## Call this when the player presses Space/Enter on a no-choice node.
func advance() -> void:
	if current_node == null or not is_active:
		return

	if current_node.is_end:
		end_dialogue()
		return

	# If there are visible choices, do nothing — the UI should use select_choice().
	if not get_visible_choices().is_empty():
		return

	# Auto-advance to next_node_id.
	if current_node.next_node_id != &"":
		var next: DialogueNode = current_tree.get_node_by_id(current_node.next_node_id) as DialogueNode
		if next:
			_set_current_node(next)
		else:
			push_warning("DialogueManager: Next node '%s' not found" % current_node.next_node_id)
			end_dialogue()
	else:
		end_dialogue()


## Select a choice by its index in the visible choices array.
func select_choice(index: int) -> void:
	if current_node == null or not is_active:
		return

	var visible: Array = get_visible_choices()
	if index < 0 or index >= visible.size():
		push_warning("DialogueManager: Choice index %d out of range" % index)
		return

	var choice: DialogueChoice = visible[index]

	# Evaluate non-skill conditions (has_item, has_flag, etc.).
	# Skill checks are rolled now; other conditions gate selection.
	for cond in choice.conditions:
		var cond_type: String = cond.get("type", "")
		if cond_type == "skill_check":
			var success: bool = _resolve_skill_check(cond)
			if not success:
				# Skill check failed — branch to fail node if specified.
				var fail_node_id: StringName = cond.get("fail_node_id", &"")
				if fail_node_id != &"":
					var fail_node: DialogueNode = current_tree.get_node_by_id(fail_node_id) as DialogueNode
					if fail_node:
						EventBus.dialogue_choice_made.emit(index)
						_execute_events(choice.events)
						_set_current_node(fail_node)
						return
				# No fail node — just stay / end.
				return
		else:
			if not evaluate_condition(cond):
				return

	EventBus.dialogue_choice_made.emit(index)

	# Execute choice events.
	_execute_events(choice.events)

	# Navigate to the choice's target node.
	if choice.next_node_id != &"":
		var next: DialogueNode = current_tree.get_node_by_id(choice.next_node_id) as DialogueNode
		if next:
			_set_current_node(next)
		else:
			push_warning("DialogueManager: Choice target node '%s' not found" % choice.next_node_id)
			end_dialogue()
	else:
		end_dialogue()


## End the current dialogue and restore the previous game state.
func end_dialogue() -> void:
	if not is_active:
		return

	is_active = false
	current_tree = null
	current_node = null

	var encounter_id: StringName = _pending_encounter_id
	_pending_encounter_id = &""

	GameManager.change_state(GameManager.previous_state)
	EventBus.dialogue_ended.emit()
	dialogue_finished.emit()

	# Start queued combat encounter after dialogue has fully closed.
	if encounter_id != &"":
		_start_pending_encounter.call_deferred(encounter_id)


## Return the list of choices whose visible_conditions all pass.
func get_visible_choices() -> Array:
	if current_node == null:
		return []

	var result: Array = []
	for choice in current_node.choices:
		if choice == null:
			continue
		var visible: bool = true
		for cond in choice.visible_conditions:
			if not evaluate_condition(cond):
				visible = false
				break
		if visible:
			result.append(choice)
	return result


# ---------------------------------------------------------------------------
# Internal — node navigation
# ---------------------------------------------------------------------------

func _set_current_node(node: DialogueNode) -> void:
	current_node = node
	_execute_events(node.events)
	node_changed.emit(node)


# ---------------------------------------------------------------------------
# Condition evaluation
# ---------------------------------------------------------------------------

## Evaluate a single condition dictionary. Returns true if the condition passes.
func evaluate_condition(cond: Dictionary) -> bool:
	var cond_type: String = cond.get("type", "")
	var character: Resource = PartyManager.get_active_character()

	match cond_type:
		"has_item":
			return _check_has_item(cond.get("item_id", ""))
		"has_flag":
			return QuestManager.has_flag(cond.get("flag", ""))
		"not_flag":
			return not QuestManager.has_flag(cond.get("flag", ""))
		"quest_complete":
			return QuestManager.is_quest_complete(cond.get("quest_id", ""))
		"quest_active":
			return QuestManager.is_quest_active(cond.get("quest_id", ""))
		"min_level":
			if character:
				return character.level >= cond.get("level", 1)
			return false
		"skill_check":
			# For visibility purposes, skill checks always show.
			return true
		_:
			push_warning("DialogueManager: Unknown condition type '%s'" % cond_type)
			return true


## Check whether any party member has an item with the given id.
func _check_has_item(item_id: String) -> bool:
	for member in PartyManager.party:
		for entry in member.inventory:
			var item: Resource = null
			if entry is InventoryEntry:
				item = entry.item
			else:
				item = entry
			if item and str(item.get("id")) == item_id:
				return true
	return false


# ---------------------------------------------------------------------------
# Internal — skill check resolution
# ---------------------------------------------------------------------------

## Roll a skill check and emit the result. Returns true on success.
func _resolve_skill_check(cond: Dictionary) -> bool:
	var skill: StringName = StringName(cond.get("skill", "persuasion"))
	var dc: int = cond.get("dc", 10)
	var character: Resource = PartyManager.get_active_character()
	if character == null:
		return false

	var modifier: int = RulesEngine.get_skill_modifier(character, skill)
	var result: DiceRoller.D20Result = DiceRoller.ability_check(modifier)
	var success: bool = result.total >= dc

	var result_str: String = "SUCCESS" if success else "FAILURE"
	print("DialogueManager: %s check — rolled %d (natural %d + %d) vs DC %d — %s" % [
		str(skill).capitalize(), result.total, result.natural_roll, modifier, dc, result_str
	])

	skill_check_resolved.emit(skill, dc, result.total, success)
	EventBus.skill_check_made.emit(character, skill, {
		"total": result.total,
		"natural_roll": result.natural_roll,
		"modifier": modifier,
		"dc": dc,
		"success": success,
	})

	return success


# ---------------------------------------------------------------------------
# Internal — event execution
# ---------------------------------------------------------------------------

## Execute an array of event dictionaries.
func _execute_events(events: Array) -> void:
	for event in events:
		if event is Dictionary:
			_execute_event(event)


## Execute a single event dictionary.
func _execute_event(event: Dictionary) -> void:
	var event_type: String = event.get("type", "")

	match event_type:
		"start_quest":
			QuestManager.start_quest(StringName(event.get("quest_id", "")))
		"complete_quest":
			QuestManager.complete_quest(StringName(event.get("quest_id", "")))
		"advance_objective":
			QuestManager.advance_objective(
				StringName(event.get("quest_id", "")),
				StringName(event.get("objective_id", "")),
				event.get("amount", 1)
			)
		"give_item":
			var item_id: String = event.get("item_id", "")
			var item: Resource = DataRegistry.get_item(StringName(item_id))
			if item:
				var character: Resource = PartyManager.get_active_character()
				if character and character is CharacterData:
					InventorySystem.add_item(character as CharacterData, item, event.get("quantity", 1))
		"take_item":
			var item_id: String = event.get("item_id", "")
			var item: Resource = DataRegistry.get_item(StringName(item_id))
			if item:
				var character: Resource = PartyManager.get_active_character()
				if character and character is CharacterData:
					InventorySystem.remove_item(character as CharacterData, item, event.get("quantity", 1))
		"give_gold":
			var character: Resource = PartyManager.get_active_character()
			if character and character is CharacterData:
				InventorySystem.add_gold(character as CharacterData, event.get("amount", 0))
		"set_flag":
			QuestManager.set_flag(event.get("flag", ""), event.get("value", true))
		"heal_party":
			PartyManager.heal_party(event.get("amount", 0))
		"start_combat":
			_pending_encounter_id = StringName(event.get("encounter_id", ""))
		_:
			push_warning("DialogueManager: Unknown event type '%s'" % event_type)


## Trigger a combat encounter after dialogue has closed. Called deferred.
func _start_pending_encounter(encounter_id: StringName) -> void:
	var encounter: CombatEncounterData = DataRegistry.get_encounter(encounter_id)
	if encounter == null:
		push_warning("DialogueManager: Unknown encounter '%s'" % encounter_id)
		return

	# Find the GridDungeonController in the scene tree.
	var controller: Node = _find_dungeon_controller()
	if controller and controller.has_method("start_encounter"):
		controller.start_encounter(encounter)
	else:
		push_warning("DialogueManager: No GridDungeonController found to start encounter")


## Walk up the scene tree to find the active GridDungeonController.
func _find_dungeon_controller() -> Node:
	var root: Node = get_tree().current_scene
	if root is GridDungeonController:
		return root
	# Search children.
	for child in root.get_children():
		if child is GridDungeonController:
			return child
	return root

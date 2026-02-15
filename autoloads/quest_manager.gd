## Quest tracking and story flag management.
##
## Registered as an autoload singleton. Manages active/completed quests,
## advances objectives via EventBus auto-tracking (kills, item pickups,
## interactions), and stores persistent story flags.
extends Node

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Active quests keyed by quest id. Values are deep-duplicated QuestData.
var active_quests: Dictionary = {}

## Completed quest ids.
var completed_quests: Dictionary = {}

## Persistent story flags (String -> Variant).
var story_flags: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Auto-track kill objectives.
	EventBus.character_died.connect(_on_character_died)
	# Auto-track item collect objectives.
	EventBus.item_acquired.connect(_on_item_acquired)
	# Auto-track interaction objectives (talk).
	EventBus.interaction_triggered.connect(_on_interaction_triggered)


# ---------------------------------------------------------------------------
# Public API — Quests
# ---------------------------------------------------------------------------

## Start a quest by id. Deep-duplicates the data to avoid shared mutation.
## Returns true if the quest was started successfully.
func start_quest(quest_id: StringName) -> bool:
	if quest_id in active_quests:
		push_warning("QuestManager: Quest '%s' is already active" % quest_id)
		return false
	if quest_id in completed_quests:
		push_warning("QuestManager: Quest '%s' is already completed" % quest_id)
		return false

	var quest_data: QuestData = DataRegistry.get_quest(quest_id)
	if quest_data == null:
		push_warning("QuestManager: Unknown quest '%s'" % quest_id)
		return false

	# Check prerequisites.
	for prereq in quest_data.prerequisite_quests:
		if prereq not in completed_quests:
			push_warning("QuestManager: Prerequisite '%s' not met for quest '%s'" % [prereq, quest_id])
			return false

	# Deep-duplicate to avoid shared resource mutation.
	var quest_copy: QuestData = quest_data.duplicate(true) as QuestData
	active_quests[quest_id] = quest_copy

	EventBus.quest_started.emit(quest_id)
	print("QuestManager: Quest started — '%s'" % quest_copy.display_name)
	return true


## Advance an objective's progress by the given amount.
func advance_objective(quest_id: StringName, objective_id: StringName, amount: int = 1) -> void:
	if quest_id not in active_quests:
		return

	var quest: QuestData = active_quests[quest_id]
	for obj in quest.objectives:
		if obj is QuestObjective and obj.id == objective_id:
			obj.current_count = mini(obj.current_count + amount, obj.required_count)
			EventBus.quest_objective_updated.emit(quest_id, objective_id)

			# Check if all required objectives are done.
			if _all_required_complete(quest):
				complete_quest(quest_id)
			return


## Complete a quest, award rewards, and move it to completed.
func complete_quest(quest_id: StringName) -> void:
	if quest_id not in active_quests:
		return

	var quest: QuestData = active_quests[quest_id]
	active_quests.erase(quest_id)
	completed_quests[quest_id] = quest

	# Set a completion flag for dialogue condition checks.
	set_flag("quest_complete_%s" % quest_id, true)

	# Award rewards.
	_award_rewards(quest)

	EventBus.quest_completed.emit(quest_id)
	print("QuestManager: Quest completed — '%s'" % quest.display_name)


## Whether a quest is currently active.
func is_quest_active(quest_id: StringName) -> bool:
	return quest_id in active_quests


## Whether a quest has been completed.
func is_quest_complete(quest_id: StringName) -> bool:
	return quest_id in completed_quests


## Get the active quest data (the duplicated copy), or null.
func get_active_quest(quest_id: StringName) -> QuestData:
	return active_quests.get(quest_id) as QuestData


## Get all active quests as an array.
func get_all_active_quests() -> Array:
	return active_quests.values()


## Get all completed quests as an array.
func get_all_completed_quests() -> Array:
	return completed_quests.values()


# ---------------------------------------------------------------------------
# Public API — Story Flags
# ---------------------------------------------------------------------------

## Set a story flag.
func set_flag(flag: String, value: Variant = true) -> void:
	story_flags[flag] = value


## Get the value of a story flag (defaults to null).
func get_flag(flag: String) -> Variant:
	return story_flags.get(flag)


## Whether a story flag exists and is truthy.
func has_flag(flag: String) -> bool:
	return story_flags.get(flag, false) == true


# ---------------------------------------------------------------------------
# Internal — auto-tracking listeners
# ---------------------------------------------------------------------------

func _on_character_died(character: Resource) -> void:
	# Check if this is a monster with an id we can track.
	var monster_id: String = ""
	if character.get("id") != null:
		monster_id = str(character.id)
	elif character.get("monster_name") != null:
		monster_id = str(character.monster_name).to_snake_case()

	if monster_id.is_empty():
		return

	for quest_id in active_quests.keys():
		var quest: QuestData = active_quests[quest_id]
		for obj in quest.objectives:
			if obj is QuestObjective and obj.objective_type == &"kill" and str(obj.target_id) == monster_id:
				advance_objective(quest_id, obj.id)


func _on_item_acquired(_character: Resource, item: Resource) -> void:
	var item_id: String = str(item.get("id")) if item.get("id") != null else ""
	if item_id.is_empty():
		return

	for quest_id in active_quests.keys():
		var quest: QuestData = active_quests[quest_id]
		for obj in quest.objectives:
			if obj is QuestObjective and obj.objective_type == &"collect" and str(obj.target_id) == item_id:
				advance_objective(quest_id, obj.id)


func _on_interaction_triggered(interactable: Node) -> void:
	var npc_id: String = ""
	if interactable.get("npc_id") != null:
		npc_id = str(interactable.npc_id)
	elif interactable.get("interactable_id") != null:
		npc_id = str(interactable.interactable_id)

	if npc_id.is_empty():
		return

	for quest_id in active_quests.keys():
		var quest: QuestData = active_quests[quest_id]
		for obj in quest.objectives:
			if obj is QuestObjective and obj.objective_type == &"talk" and str(obj.target_id) == npc_id:
				advance_objective(quest_id, obj.id)


# ---------------------------------------------------------------------------
# Internal — helpers
# ---------------------------------------------------------------------------

## Check if all required (non-optional) objectives are complete.
func _all_required_complete(quest: QuestData) -> bool:
	for obj in quest.objectives:
		if obj is QuestObjective and not obj.is_optional and not obj.is_complete():
			return false
	return true


## Award quest rewards to the active party.
func _award_rewards(quest: QuestData) -> void:
	# Award XP to all party members.
	if quest.rewards_xp > 0:
		for member in PartyManager.party:
			if member.get("experience_points") != null:
				member.experience_points += quest.rewards_xp
				EventBus.experience_gained.emit(member, quest.rewards_xp)

	# Award gold to the active character.
	if quest.rewards_gold > 0:
		var character: Resource = PartyManager.get_active_character()
		if character and character is CharacterData:
			InventorySystem.add_gold(character as CharacterData, quest.rewards_gold)

	# Award items to the active character.
	for item in quest.rewards_items:
		if item != null:
			var character: Resource = PartyManager.get_active_character()
			if character and character is CharacterData:
				InventorySystem.add_item(character as CharacterData, item)

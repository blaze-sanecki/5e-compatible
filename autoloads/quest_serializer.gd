class_name QuestSerializer
extends RefCounted

## Serializes and deserializes quest state (active quests, completed quests,
## story flags) to/from JSON-compatible dictionaries for save files.


static func serialize() -> Dictionary:
	var active: Dictionary = {}
	for quest_id in QuestManager.active_quests:
		var quest: QuestData = QuestManager.active_quests[quest_id]
		var objectives: Array = []
		for obj in quest.objectives:
			if obj is QuestObjective:
				objectives.append({
					"id": str(obj.id),
					"current_count": obj.current_count,
				})
		active[str(quest_id)] = {"objectives": objectives}

	var completed: Array = []
	for quest_id in QuestManager.completed_quests:
		completed.append(str(quest_id))

	var flags: Dictionary = {}
	for key in QuestManager.story_flags:
		flags[str(key)] = QuestManager.story_flags[key]

	return {
		"active": active,
		"completed": completed,
		"story_flags": flags,
	}


static func deserialize(quests_data: Dictionary) -> void:
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	QuestManager.story_flags.clear()

	# Restore active quests.
	var active: Dictionary = quests_data.get("active", {})
	for quest_id_str in active:
		var quest_id: StringName = StringName(quest_id_str)
		var quest_template: QuestData = DataRegistry.get_quest(quest_id)
		if quest_template == null:
			push_warning("QuestSerializer: Unknown quest '%s' in save" % quest_id_str)
			continue

		var quest_copy: QuestData = quest_template.duplicate(true) as QuestData
		var saved_objectives: Array = active[quest_id_str].get("objectives", [])

		# Restore objective progress.
		for saved_obj in saved_objectives:
			var obj_id: String = str(saved_obj.get("id", ""))
			var count: int = int(saved_obj.get("current_count", 0))
			for obj in quest_copy.objectives:
				if obj is QuestObjective and str(obj.id) == obj_id:
					obj.current_count = count
					break

		QuestManager.active_quests[quest_id] = quest_copy

	# Restore completed quests.
	var completed: Array = quests_data.get("completed", [])
	for quest_id_str in completed:
		var quest_id: StringName = StringName(quest_id_str)
		QuestManager.completed_quests[quest_id] = true

	# Restore story flags.
	var flags: Dictionary = quests_data.get("story_flags", {})
	for key in flags:
		QuestManager.story_flags[key] = flags[key]

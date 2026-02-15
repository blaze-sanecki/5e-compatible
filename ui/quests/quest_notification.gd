class_name QuestNotification
extends CanvasLayer

## Toast notification at the top of the screen for quest events.
## Shows "New Quest: {name}", "Quest Complete: {name}", or
## "Objective Updated: {desc}" and fades out after 3 seconds.

var _container: VBoxContainer


func _ready() -> void:
	layer = 22
	_build_ui()

	EventBus.quest_started.connect(_on_quest_started)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.quest_objective_updated.connect(_on_objective_updated)


func _on_quest_started(quest_id: StringName) -> void:
	var quest: QuestData = DataRegistry.get_quest(quest_id)
	if quest:
		_show_toast("New Quest: %s" % quest.display_name, UITheme.COLOR_TITLE)


func _on_quest_completed(quest_id: StringName) -> void:
	# Look in completed quests (QuestManager has already moved it there).
	var quest: QuestData = null
	for q in QuestManager.get_all_completed_quests():
		if q.id == quest_id:
			quest = q
			break
	if quest == null:
		quest = DataRegistry.get_quest(quest_id)
	if quest:
		_show_toast("Quest Complete: %s" % quest.display_name, UITheme.COLOR_SUCCESS)


func _on_objective_updated(quest_id: StringName, objective_id: StringName) -> void:
	var quest: QuestData = QuestManager.get_active_quest(quest_id)
	if quest == null:
		return
	for obj in quest.objectives:
		if obj is QuestObjective and obj.id == objective_id:
			_show_toast("Objective: %s (%d/%d)" % [obj.description, obj.current_count, obj.required_count], UITheme.COLOR_QUEST_OBJECTIVE)
			return


func _show_toast(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.modulate.a = 0.0
	_container.add_child(label)

	# Fade in.
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)


func _build_ui() -> void:
	_container = VBoxContainer.new()
	_container.anchor_left = 0.2
	_container.anchor_right = 0.8
	_container.anchor_top = 0.02
	_container.anchor_bottom = 0.15
	_container.offset_left = 0
	_container.offset_right = 0
	_container.offset_top = 0
	_container.offset_bottom = 0
	_container.add_theme_constant_override("separation", 4)
	add_child(_container)

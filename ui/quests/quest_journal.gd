class_name QuestJournal
extends CanvasLayer

## Full-screen quest journal opened via J key.
## Left panel: active/completed quest list.
## Right panel: selected quest details with objectives and rewards.

var _root: Control
var _panel: PanelContainer
var _quest_list: VBoxContainer
var _detail_panel: VBoxContainer
var _detail_title: Label
var _detail_desc: RichTextLabel
var _objectives_list: VBoxContainer
var _rewards_label: Label
var _close_btn: Button

## Currently selected quest data for display.
var _selected_quest: QuestData = null
## Whether the selected quest is completed.
var _selected_is_completed: bool = false


func _ready() -> void:
	layer = 15
	_build_ui()
	_hide_journal()

	EventBus.quest_started.connect(func(_id: StringName) -> void: _refresh_list())
	EventBus.quest_completed.connect(func(_id: StringName) -> void: _refresh_list())
	EventBus.quest_objective_updated.connect(func(_qid: StringName, _oid: StringName) -> void: _refresh_detail())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_J:
			if _root.visible:
				_hide_journal()
			else:
				_show_journal()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_ESCAPE and _root.visible:
			_hide_journal()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Show / Hide
# ---------------------------------------------------------------------------

func _show_journal() -> void:
	_refresh_list()
	_root.visible = true


func _hide_journal() -> void:
	_root.visible = false


# ---------------------------------------------------------------------------
# List refresh
# ---------------------------------------------------------------------------

func _refresh_list() -> void:
	for child in _quest_list.get_children():
		child.queue_free()

	# Active quests header.
	var active_quests: Array = QuestManager.get_all_active_quests()
	if not active_quests.is_empty():
		var header := Label.new()
		header.text = "Active Quests"
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
		_quest_list.add_child(header)

		for quest in active_quests:
			_add_quest_button(quest, false)

	# Completed quests header.
	var completed_quests: Array = QuestManager.get_all_completed_quests()
	if not completed_quests.is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		_quest_list.add_child(spacer)

		var header := Label.new()
		header.text = "Completed"
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", UITheme.COLOR_QUEST_COMPLETE)
		_quest_list.add_child(header)

		for quest in completed_quests:
			_add_quest_button(quest, true)

	if active_quests.is_empty() and completed_quests.is_empty():
		var empty := Label.new()
		empty.text = "No quests yet."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_quest_list.add_child(empty)

	_refresh_detail()


func _add_quest_button(quest: QuestData, completed: bool) -> void:
	var btn := Button.new()
	btn.text = quest.display_name
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if completed:
		btn.modulate = Color(0.6, 0.6, 0.6)
	btn.pressed.connect(func() -> void:
		_selected_quest = quest
		_selected_is_completed = completed
		_refresh_detail()
	)
	_quest_list.add_child(btn)


# ---------------------------------------------------------------------------
# Detail refresh
# ---------------------------------------------------------------------------

func _refresh_detail() -> void:
	if _selected_quest == null:
		_detail_title.text = "Select a quest"
		_detail_desc.text = ""
		for child in _objectives_list.get_children():
			child.queue_free()
		_rewards_label.text = ""
		return

	_detail_title.text = _selected_quest.display_name
	_detail_desc.text = _selected_quest.description

	# Objectives.
	for child in _objectives_list.get_children():
		child.queue_free()

	for obj in _selected_quest.objectives:
		if obj is QuestObjective:
			var line := Label.new()
			var check: String = "[x]" if obj.is_complete() else "[ ]"
			var optional_tag: String = " (Optional)" if obj.is_optional else ""
			if obj.required_count > 1:
				line.text = "%s %s (%d/%d)%s" % [check, obj.description, obj.current_count, obj.required_count, optional_tag]
			else:
				line.text = "%s %s%s" % [check, obj.description, optional_tag]

			if obj.is_complete():
				line.add_theme_color_override("font_color", UITheme.COLOR_QUEST_COMPLETE)
			line.add_theme_font_size_override("font_size", 13)
			_objectives_list.add_child(line)

	# Rewards.
	var rewards_parts: PackedStringArray = []
	if _selected_quest.rewards_xp > 0:
		rewards_parts.append("%d XP" % _selected_quest.rewards_xp)
	if _selected_quest.rewards_gold > 0:
		rewards_parts.append("%d Gold" % _selected_quest.rewards_gold)
	for item in _selected_quest.rewards_items:
		if item != null:
			var item_name: String = str(item.get("display_name")) if item.get("display_name") else str(item.get("id"))
			rewards_parts.append(item_name)

	_rewards_label.text = "Rewards: " + ", ".join(rewards_parts) if not rewards_parts.is_empty() else ""


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dim background.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	_root.add_child(bg)

	# Main panel.
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.1
	_panel.anchor_right = 0.9
	_panel.anchor_top = 0.1
	_panel.anchor_bottom = 0.9
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	_panel.add_theme_stylebox_override("panel", UIStyler.create_panel_style(
		Color(0.12, 0.12, 0.18, 0.95)))
	_root.add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(main_vbox)

	# Title bar.
	var title_bar := HBoxContainer.new()
	main_vbox.add_child(title_bar)

	var title := Label.new()
	title.text = "Quest Journal"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.pressed.connect(_hide_journal)
	title_bar.add_child(_close_btn)

	# Split content.
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(hsplit)

	# Left: quest list.
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(200, 0)
	hsplit.add_child(left_scroll)

	_quest_list = VBoxContainer.new()
	_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.add_theme_constant_override("separation", 4)
	left_scroll.add_child(_quest_list)

	# Right: detail panel.
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.add_child(right_scroll)

	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.add_theme_constant_override("separation", 8)
	right_scroll.add_child(_detail_panel)

	_detail_title = Label.new()
	_detail_title.text = "Select a quest"
	_detail_title.add_theme_font_size_override("font_size", 18)
	_detail_title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	_detail_panel.add_child(_detail_title)

	_detail_desc = RichTextLabel.new()
	_detail_desc.bbcode_enabled = true
	_detail_desc.fit_content = true
	_detail_desc.scroll_active = false
	_detail_desc.add_theme_font_size_override("normal_font_size", 13)
	_detail_panel.add_child(_detail_desc)

	var obj_header := Label.new()
	obj_header.text = "Objectives"
	obj_header.add_theme_font_size_override("font_size", 15)
	obj_header.add_theme_color_override("font_color", UITheme.COLOR_QUEST_OBJECTIVE)
	_detail_panel.add_child(obj_header)

	_objectives_list = VBoxContainer.new()
	_objectives_list.add_theme_constant_override("separation", 4)
	_detail_panel.add_child(_objectives_list)

	_rewards_label = Label.new()
	_rewards_label.add_theme_font_size_override("font_size", 13)
	_rewards_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	_detail_panel.add_child(_rewards_label)

	add_child(_root)

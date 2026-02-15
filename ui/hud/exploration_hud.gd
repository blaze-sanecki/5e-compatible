extends CanvasLayer

## Exploration HUD — party HP bars (top-left) and active quest tracker
## (bottom-right). Instantiated by PersistentUI autoload.

var _hp_container: VBoxContainer
var _quest_container: VBoxContainer
var _quest_title: Label
var _quest_objective: Label

## Map of CharacterData -> HBoxContainer for HP bar updates.
var _hp_bars: Dictionary = {}


func _ready() -> void:
	layer = 8
	_build_ui()

	EventBus.character_damaged.connect(_on_hp_changed)
	EventBus.character_healed.connect(_on_hp_changed_heal)
	EventBus.party_member_added.connect(func(_c: Resource) -> void: _refresh_hp_bars())
	EventBus.party_member_removed.connect(func(_c: Resource) -> void: _refresh_hp_bars())
	EventBus.quest_started.connect(func(_id: StringName) -> void: _refresh_quest())
	EventBus.quest_completed.connect(func(_id: StringName) -> void: _refresh_quest())
	EventBus.quest_objective_updated.connect(func(_qid: StringName, _oid: StringName) -> void: _refresh_quest())
	EventBus.rest_completed.connect(func(_type: StringName) -> void: _refresh_hp_bars())

	# Delay initial refresh by one frame so PartyManager is populated.
	await get_tree().process_frame
	_refresh_hp_bars()
	_refresh_quest()


func _build_ui() -> void:
	# --- HP Bars (top-left) ---
	_hp_container = VBoxContainer.new()
	_hp_container.anchor_left = 0.0
	_hp_container.anchor_top = 0.0
	_hp_container.anchor_right = 0.0
	_hp_container.anchor_bottom = 0.0
	_hp_container.offset_left = 12
	_hp_container.offset_top = 12
	_hp_container.offset_right = 220
	_hp_container.offset_bottom = 200
	_hp_container.add_theme_constant_override("separation", 4)
	add_child(_hp_container)

	# --- Quest Tracker (bottom-right) ---
	_quest_container = VBoxContainer.new()
	_quest_container.anchor_left = 1.0
	_quest_container.anchor_top = 1.0
	_quest_container.anchor_right = 1.0
	_quest_container.anchor_bottom = 1.0
	_quest_container.offset_left = -260
	_quest_container.offset_top = -80
	_quest_container.offset_right = -12
	_quest_container.offset_bottom = -12
	_quest_container.add_theme_constant_override("separation", 2)
	add_child(_quest_container)

	_quest_title = Label.new()
	_quest_title.add_theme_font_size_override("font_size", 13)
	_quest_title.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	_quest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quest_container.add_child(_quest_title)

	_quest_objective = Label.new()
	_quest_objective.add_theme_font_size_override("font_size", 11)
	_quest_objective.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_quest_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quest_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_container.add_child(_quest_objective)


# ---------------------------------------------------------------------------
# HP Bars
# ---------------------------------------------------------------------------

func _refresh_hp_bars() -> void:
	for child in _hp_container.get_children():
		child.queue_free()
	_hp_bars.clear()

	for member in PartyManager.party:
		_add_hp_bar(member)


func _add_hp_bar(character: Resource) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Name label.
	var name_label := Label.new()
	var char_name: String = str(character.get("character_name")) if character.get("character_name") else "Hero"
	name_label.text = char_name
	name_label.custom_minimum_size = Vector2(70, 0)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.7))
	name_label.clip_text = true
	row.add_child(name_label)

	# HP bar background.
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(100, 14)
	bar_bg.color = UITheme.COLOR_HP_BG
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_bg)

	# HP bar fill.
	var bar_fill := ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(0, 14)
	bar_fill.color = UITheme.COLOR_HP_HIGH
	bar_bg.add_child(bar_fill)

	# HP text.
	var hp_label := Label.new()
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.add_child(hp_label)

	_hp_container.add_child(row)
	_hp_bars[character] = {"bar_bg": bar_bg, "bar_fill": bar_fill, "hp_label": hp_label}
	_update_hp_bar(character)


func _update_hp_bar(character: Resource) -> void:
	if character not in _hp_bars:
		return

	var current: int = character.get("current_hp") if character.get("current_hp") != null else 0
	var maximum: int = character.get("max_hp") if character.get("max_hp") != null else 1
	maximum = maxi(maximum, 1)

	var ratio: float = clampf(float(current) / float(maximum), 0.0, 1.0)

	var entry: Dictionary = _hp_bars[character]
	var bar_bg: ColorRect = entry["bar_bg"]
	var bar_fill: ColorRect = entry["bar_fill"]
	var hp_label: Label = entry["hp_label"]

	# Set fill width as ratio of parent.
	bar_fill.custom_minimum_size.x = bar_bg.custom_minimum_size.x * ratio
	bar_fill.size.x = bar_bg.size.x * ratio

	# Color based on health percentage.
	if ratio > 0.5:
		bar_fill.color = UITheme.COLOR_HP_HIGH
	elif ratio > 0.25:
		bar_fill.color = UITheme.COLOR_HP_MID
	else:
		bar_fill.color = UITheme.COLOR_HP_LOW

	hp_label.text = "%d/%d" % [current, maximum]


func _on_hp_changed(character: Resource, _amount: int, _type: StringName) -> void:
	_update_hp_bar(character)


func _on_hp_changed_heal(character: Resource, _amount: int) -> void:
	_update_hp_bar(character)


# ---------------------------------------------------------------------------
# Quest Tracker
# ---------------------------------------------------------------------------

func _refresh_quest() -> void:
	var quests: Array = QuestManager.get_all_active_quests()
	if quests.is_empty():
		_quest_title.text = ""
		_quest_objective.text = ""
		return

	# Show the first active quest.
	var quest: Resource = quests[0]
	_quest_title.text = str(quest.get("display_name")) if quest.get("display_name") else ""

	# Find the first incomplete objective.
	var obj_text: String = ""
	if quest.get("objectives") != null:
		for obj in quest.objectives:
			if obj.has_method("is_complete") and not obj.is_complete():
				var desc: String = str(obj.get("description")) if obj.get("description") else ""
				if obj.get("required_count") != null and obj.required_count > 1:
					obj_text = "%s (%d/%d)" % [desc, obj.current_count, obj.required_count]
				else:
					obj_text = desc
				break

	_quest_objective.text = obj_text

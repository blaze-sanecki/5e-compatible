extends Control

## Step 5: Skill proficiency selection.
## Background skills are shown locked; class skills are selectable with a count tracker.

var _creator: CharacterCreator
var _class_skill_checks: Dictionary = {}  # skill_name -> CheckBox
var _selected_skills: Array[StringName] = []

@onready var skill_container: VBoxContainer = %SkillContainer
@onready var info_label: Label = %InfoLabel


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	if _creator == null:
		return

	var bg_skills: Array[StringName] = _creator.get_background_skills()
	var class_skills: Array[StringName] = _creator.get_available_class_skills()

	# Background skills — locked on.
	if bg_skills.size() > 0:
		var bg_header := Label.new()
		bg_header.text = "Background Skills (automatic):"
		skill_container.add_child(bg_header)

		for skill in bg_skills:
			var cb := CheckBox.new()
			cb.text = String(skill).capitalize().replace("_", " ")
			cb.button_pressed = true
			cb.disabled = true
			skill_container.add_child(cb)

		var spacer := HSeparator.new()
		skill_container.add_child(spacer)

	# Class skills — selectable.
	var class_header := Label.new()
	class_header.text = "Choose %d class skills:" % _creator.chosen_class.num_skill_choices
	skill_container.add_child(class_header)

	for skill in class_skills:
		var cb := CheckBox.new()
		cb.text = String(skill).capitalize().replace("_", " ")
		cb.toggled.connect(_on_skill_toggled.bind(skill))
		skill_container.add_child(cb)
		_class_skill_checks[skill] = cb

	# Restore previous selections.
	for skill in _creator.chosen_skills:
		if skill in _class_skill_checks:
			_class_skill_checks[skill].button_pressed = true
			_selected_skills.append(skill)

	_update_info()


func _on_skill_toggled(toggled_on: bool, skill: StringName) -> void:
	if toggled_on:
		if _selected_skills.size() >= _creator.chosen_class.num_skill_choices:
			# Already at max — uncheck this one.
			_class_skill_checks[skill].button_pressed = false
			return
		if skill not in _selected_skills:
			_selected_skills.append(skill)
	else:
		_selected_skills.erase(skill)

	_update_info()
	_refresh_parent()


func _update_info() -> void:
	var max_picks: int = _creator.chosen_class.num_skill_choices if _creator.chosen_class != null else 0
	info_label.text = "Selected: %d / %d" % [_selected_skills.size(), max_picks]


func _refresh_parent() -> void:
	var parent_screen = get_parent()
	while parent_screen != null and not parent_screen.has_method("refresh_navigation"):
		parent_screen = parent_screen.get_parent()
	if parent_screen != null:
		parent_screen.refresh_navigation()


func is_valid() -> bool:
	if _creator == null or _creator.chosen_class == null:
		return false
	return _selected_skills.size() == _creator.chosen_class.num_skill_choices


func apply(creator: CharacterCreator) -> void:
	creator.set_skills(_selected_skills)
